using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[VolumeComponentMenu("CustomPost/Glitch/RGBSplit")]
public class CustomRGBSplit : PostVolumeComponentBase
{
    public ClampedFloatParameter Intensity = new ClampedFloatParameter(0.0f, 0.0f, 0.1f);
    private Material _material;
    public override void Setup()
    {
        if (_material == null)
            _material = CoreUtils.CreateEngineMaterial("CustomPost/Glitch/RGBSplit");
    }

    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source,
        RenderTargetIdentifier destination)
    {
        if (_material == null)
            return;
        
        cmd.SetGlobalFloat(Shader.PropertyToID("_Intensity"), Intensity.value);
        cmd.Blit(source, destination, _material);
    }

    public override bool IsActive()
    {
        return active;
    }
}
