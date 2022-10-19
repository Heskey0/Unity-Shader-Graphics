using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[VolumeComponentMenu("CustomPost/Glitch/WaveJitter")]
public class CustomWaveJitter : PostVolumeComponentBase
{
    public ClampedFloatParameter Frequency = new ClampedFloatParameter(0.0f, 0.0f,5.0f);
    public ClampedFloatParameter Speed = new ClampedFloatParameter(0.0f, 0.0f,5.0f);
    public ClampedFloatParameter Amount = new ClampedFloatParameter(0.0f, 0.0f,5.0f);
    public ClampedFloatParameter RGBSplit = new ClampedFloatParameter(0.0f, 0.0f,5.0f);
    
    private Material _material;
    public override void Setup()
    {
        if (_material == null)
            _material = CoreUtils.CreateEngineMaterial("CustomPost/Glitch/WaveJitter");
    }

    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source,
        RenderTargetIdentifier destination)
    {
        if (_material == null)
            return;
        cmd.SetGlobalFloat(Shader.PropertyToID("_Frequency"), Frequency.value);
        cmd.SetGlobalFloat(Shader.PropertyToID("_Speed"), Speed.value);
        cmd.SetGlobalFloat(Shader.PropertyToID("_Amount"), Amount.value);
        cmd.SetGlobalFloat(Shader.PropertyToID("_RGBSplit"), RGBSplit.value);
        cmd.Blit(source, destination, _material);
    }

    public override bool IsActive()
    {
        return active;
    }
}
