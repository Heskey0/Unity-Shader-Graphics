using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[VolumeComponentMenu("CustomPost/Blur/TiltShift")]
public class CustomTiltShift : PostVolumeComponentBase
{
    public ClampedIntParameter Iteration = new ClampedIntParameter(0, 0, 10);
    public ClampedFloatParameter BlurRadius = new ClampedFloatParameter(0.0f, 0.0f, 5.0f); 
    public ClampedFloatParameter _Offset = new ClampedFloatParameter(0.0f, -1.0f, 1.0f); 
    public ClampedFloatParameter _Area = new ClampedFloatParameter(0.0f, 0.0f, 5.0f); 
    public ClampedFloatParameter _Spread = new ClampedFloatParameter(0.0f, 0.0f, 5.0f); 
    
    private Material _material;
    public override void Setup()
    {
        if (_material == null)
        {
            _material = CoreUtils.CreateEngineMaterial("CustomPost/Blur/TiltShift");
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
        
        cmd.SetGlobalFloat("_Offset", _Offset.value);
        cmd.SetGlobalFloat("_Area", _Area.value);
        cmd.SetGlobalFloat("_Spread", _Spread.value);
        cmd.Blit(source, destination, _material);

    }

    public override bool IsActive()
    {
        return active;
    }
}
