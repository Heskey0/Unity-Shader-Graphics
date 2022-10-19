using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[VolumeComponentMenu("Custom/PostProcess")]
public class CustomPostVolumeComponent : PostVolumeComponentBase
{
    
    public ClampedFloatParameter foo = new ClampedFloatParameter(.5f, 0, 1f);


    public override void Setup()
    {
        
    }

    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source,
        RenderTargetIdentifier destination)
    {
        cmd.Blit(source, destination);
    }

    public override bool IsActive()
    {
        return active;
    }
}
