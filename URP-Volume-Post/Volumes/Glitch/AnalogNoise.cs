using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[VolumeComponentMenu("CustomPost/Glitch/AnalogNoise")]
public class CustomAnalogNoise : PostVolumeComponentBase
{
    public ClampedFloatParameter _Speed = new ClampedFloatParameter(0.0f, 0.0f, 1.0f);
    public ClampedFloatParameter _LuminanceJitterThreshold = new ClampedFloatParameter(0.0f, 0.0f, 1.0f);
    public ClampedFloatParameter _Fading = new ClampedFloatParameter(0.0f, 0.0f, 1.0f);
    
    private Material _material;
    public override void Setup()
    {
        if (_material == null)
        {
            _material = CoreUtils.CreateEngineMaterial("CustomPost/Glitch/AnalogNoise");
        }
    }

    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source,
        RenderTargetIdentifier destination)
    {
        if (_material == null)
        {
            return;
        }
        cmd.SetGlobalFloat("_Speed", _Speed.value);
        cmd.SetGlobalFloat("_LuminanceJitterThreshold", _LuminanceJitterThreshold.value);
        cmd.SetGlobalFloat("_Fading", _Fading.value);
        cmd.Blit(source, destination, _material);
    }

    public override bool IsActive()
    {
        return active;
    }
}
