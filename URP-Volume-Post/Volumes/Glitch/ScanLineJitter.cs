using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[VolumeComponentMenu("CustomPost/Glitch/ScanLineJitter")]
public class CustomScanLineJitter : PostVolumeComponentBase
{
    public ClampedFloatParameter _Amount = new ClampedFloatParameter(0.0f, 0.0f, 1.0f);
    public ClampedFloatParameter _Frequency = new ClampedFloatParameter(0.0f, 0.0f, 1.0f);
    public ClampedFloatParameter _Threshold = new ClampedFloatParameter(0.0f, 0.0f, 1.0f);

    private Material _material;
    public override void Setup()
    {
        if (_material == null)
        {
            _material = CoreUtils.CreateEngineMaterial("CustomPost/Glitch/ScanLineJitter");
        }
    }

    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source,
        RenderTargetIdentifier destination)
    {
        if (_material == null)
        {
            return;
        }
        cmd.SetGlobalFloat("_Amount", _Amount.value);
        cmd.SetGlobalFloat("_Frequency", _Frequency.value);
        cmd.SetGlobalFloat("_Threshold", _Threshold.value);
        cmd.Blit(source, destination, _material);
    }

    public override bool IsActive()
    {
        return active;
    }
}
