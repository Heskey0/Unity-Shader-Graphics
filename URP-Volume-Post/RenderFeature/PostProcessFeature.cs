using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class PostProcessFeature : ScriptableRendererFeature
{
    class CustomRenderPass : ScriptableRenderPass
    {
        private List<PostVolumeComponentBase> components;
        private List<int> activeComponents;
        private List<ProfilingSampler> profilingSamplers;
        
        private RenderTargetHandle source;
        private RenderTargetHandle destination;
        private RenderTargetHandle tempRT0;
        private RenderTargetHandle tempRT1;

        public bool SetupComponents()
        {
            activeComponents.Clear();
            for (int i = 0; i < components.Count; i++)
            {
                components[i].Setup();
                if (components[i].IsActive())
                {
                    activeComponents.Add(i);
                }
            }
            return activeComponents.Count != 0;
        }

        public void Setup(RenderTargetHandle source, RenderTargetHandle destination)
        {
            this.source = source;
            this.destination = destination;
        }
        public CustomRenderPass(List<PostVolumeComponentBase> volumeComponents)
        {
            components = volumeComponents;
            activeComponents = new List<int>(volumeComponents.Count);
            profilingSamplers = volumeComponents.Select(c => new ProfilingSampler(c.ToString())).ToList();
            
            tempRT0.Init("_TemporaryRenderTexture0");
            tempRT1.Init("_TemporaryRenderTexture1");
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = CommandBufferPool.Get("Custom PostProcess after PostProcess");

            var descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.msaaSamples = 1;
            descriptor.depthBufferBits = 0;

            RenderTargetIdentifier buff0, buff1;
            bool rt1Used = false;
            cmd.GetTemporaryRT(tempRT0.id, descriptor);
            buff0 = tempRT0.id;

            // 如果destination没有初始化，则需要获取RT，主要是destinaton为_AfterPostProcessTexture的情况
            if (destination != RenderTargetHandle.CameraTarget && !destination.HasInternalRenderTargetId())
            {
                cmd.GetTemporaryRT(destination.id, descriptor);
            }

            
            
            
            cmd.GetTemporaryRT(tempRT1.id, descriptor);
            buff1 = tempRT1.id;
            rt1Used = true;

            // source -> buff0
            cmd.Blit(source.Identifier(), buff0);
            for (int i = 0; i < activeComponents.Count; i++)
            {
                int index = activeComponents[i];
                var component = components[index];
                using (new ProfilingScope(cmd, profilingSamplers[index]))
                {
                    // buff0 -> buff1
                    component.Render(cmd, ref renderingData, buff0, buff1);
                }
                // buff1 -> buff0
                CoreUtils.Swap(ref buff0, ref buff1);
            }
            

            // buff0 -> destination
            cmd.Blit(buff0, destination.Identifier());


            cmd.ReleaseTemporaryRT(tempRT0.id);
            if (rt1Used)
                cmd.ReleaseTemporaryRT(tempRT1.id);
            
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
        
    }

    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingPostProcessing;
    }
    
    public Settings settings = new Settings();
    private List<PostVolumeComponentBase> components;
    CustomRenderPass m_ScriptablePass;
    private RenderTargetHandle afterPostProcessTexture;

    /// <inheritdoc/>
    public override void Create()
    {
        var stack = VolumeManager.instance.stack;
        components = VolumeManager.instance.baseComponentTypeArray
            .Where(t => t.IsSubclassOf(typeof(PostVolumeComponentBase)))
            .Select(t => stack.GetComponent(t) as PostVolumeComponentBase)
            .ToList();
        m_ScriptablePass = new CustomRenderPass(components);

        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = settings.passEvent;
        
        afterPostProcessTexture.Init("_AfterPostProcessTexture");
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.postProcessEnabled && m_ScriptablePass.SetupComponents())
        {
            var source = new RenderTargetHandle(renderer.cameraColorTarget);
            source = renderingData.cameraData.resolveFinalTarget ? afterPostProcessTexture : source;
            m_ScriptablePass.Setup(source, source);
            renderer.EnqueuePass(m_ScriptablePass);
        }
    }
}


