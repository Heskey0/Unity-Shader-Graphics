using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[VolumeComponentMenu("CustomPost/Blur/TentBlur")]
public class CustomTentBlurVolume : PostVolumeComponentBase
{

    private Material _material;
    
    public ClampedIntParameter Iteration = new ClampedIntParameter(5, 0, 15);
    public ClampedFloatParameter Offset = new ClampedFloatParameter(0.0f, 0.0f, 10.0f);
    
    public override void Setup()
    {
        if (_material == null)
            _material = CoreUtils.CreateEngineMaterial("CustomPost/Blur/TentBlur");
    }

    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source,
        RenderTargetIdentifier destination)
    {
        if (_material == null)
            return;
        
        RenderTargetIdentifier buff0, buff1;
        RenderTargetHandle tempRT0 = new RenderTargetHandle(), tempRT1 = new RenderTargetHandle();
        
        tempRT0.Init("RT0");
        tempRT1.Init("RT1");
        
        var descriptor = renderingData.cameraData.cameraTargetDescriptor;
        cmd.GetTemporaryRT(tempRT0.id, descriptor);
        cmd.GetTemporaryRT(tempRT1.id, descriptor);
        buff0 = tempRT0.id;
        buff1 = tempRT1.id;

        cmd.Blit(source, buff0);
        cmd.SetGlobalFloat(Shader.PropertyToID("_Offset"), Offset.value);
        for (int i = 0; i < Iteration.value; i++)
        {
            cmd.Blit(buff0, buff1, _material);
            cmd.Blit(buff1, buff0, _material);
        }
        
        cmd.Blit(buff0, destination, _material);
        
        cmd.ReleaseTemporaryRT(tempRT0.id);
        cmd.ReleaseTemporaryRT(tempRT1.id);
    }

    public override bool IsActive()
    {
        return active;
    }
}
