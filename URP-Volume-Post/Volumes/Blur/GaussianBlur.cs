using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[VolumeComponentMenu("CustomPost/Blur/GaussianBlur")]
public class CustomGaussianBlur : PostVolumeComponentBase
{
    private Material _material;

    public ClampedIntParameter Iteration = new ClampedIntParameter(2, 0, 8);
    
    public ClampedFloatParameter BlurOffsetX = new ClampedFloatParameter(0.0f, 0f, 0.005f);
    public ClampedFloatParameter BlurOffsetY = new ClampedFloatParameter(0.0f, 0f, 0.005f);
    public override void Setup()
    {
        if (_material == null)
            _material = CoreUtils.CreateEngineMaterial("CustomPost/Blur/GaussianBlur");
    }

    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source,
        RenderTargetIdentifier destination)
    {
        if (_material == null)
            return;

        // cmd.GetTemporaryRT(ShaderIDs.BufferRT1, RTWidth, RTHeight, 0, FilterMode.Bilinear);

        RenderTargetIdentifier buff0, buff1;
        RenderTargetHandle tempRT0 = new RenderTargetHandle(), tempRT1 = new RenderTargetHandle();
        
        tempRT0.Init("RT0");
        tempRT1.Init("RT1");
        
        var descriptor = renderingData.cameraData.cameraTargetDescriptor;
        cmd.GetTemporaryRT(tempRT0.id, descriptor);
        cmd.GetTemporaryRT(tempRT1.id, descriptor);
        buff0 = tempRT0.id;
        buff1 = tempRT1.id;
        
        
        float X = BlurOffsetX.value, Y = BlurOffsetY.value;

        cmd.Blit(source, buff0);
        for (int i = 0; i < Iteration.value; i++)
        {
            cmd.SetGlobalColor(Shader.PropertyToID("_BlurOffset"), new Vector4(X, 0, 0, 0));
            cmd.Blit(buff0, buff1, _material);
            
            cmd.SetGlobalColor(Shader.PropertyToID("_BlurOffset"), new Vector4(0, Y, 0, 0));
            cmd.Blit(buff1, buff0, _material);
        }

        cmd.Blit(buff0, destination);
        cmd.ReleaseTemporaryRT(tempRT0.id);
        cmd.ReleaseTemporaryRT(tempRT1.id);
    }

    public override bool IsActive()
    {
        return active;
    }
}
