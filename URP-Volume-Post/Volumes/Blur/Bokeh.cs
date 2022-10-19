using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[VolumeComponentMenu("CustomPost/Blur/Bokeh")]
public class CustomBokeh : PostVolumeComponentBase
{
    public ClampedIntParameter Iteration = new ClampedIntParameter(0, 0, 10);
    public ClampedFloatParameter BlurRadius = new ClampedFloatParameter(0.0f, 0.0f, 5.0f); 
    
    private Material _material;
    public override void Setup()
    {
        if (_material == null)
        {
            _material = CoreUtils.CreateEngineMaterial("CustomPost/Blur/Bokeh");
        }
    }

    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source,
        RenderTargetIdentifier destination)
    {
        if (_material == null)
        {
            return;
        }
        
        cmd.SetGlobalFloat("_Radius", BlurRadius.value);
        cmd.SetGlobalInteger("_Iteration", Iteration.value);
        cmd.Blit(source, destination, _material);

    }

    public override bool IsActive()
    {
        return active;
    }
}
