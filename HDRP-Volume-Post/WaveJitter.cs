using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using System;

[Serializable, VolumeComponentMenu("Post-processing/Custom/WaveJitter")]
public sealed class WaveJitter : CustomPostProcessVolumeComponent, IPostProcessComponent
{
    //float _Frequency;
    //float _Speed;
    //float _Amount;
    //float _RGBSplit;
    
    [Tooltip("Controls the intensity of the effect.")]
    public ClampedFloatParameter _Frequency = new ClampedFloatParameter(0f, 0f, 1f);
    public ClampedFloatParameter _Speed = new ClampedFloatParameter(0f, 0f, 1f);
    public ClampedFloatParameter _Amount = new ClampedFloatParameter(0f, 0f, 1f);
    public ClampedFloatParameter _RGBSplit = new ClampedFloatParameter(0f, 0f, 1f);

    
    Material m_Material;

    public bool IsActive() => m_Material != null && _Frequency.value > 0f && active;

    public override CustomPostProcessInjectionPoint injectionPoint => CustomPostProcessInjectionPoint.AfterPostProcess;

    public override void Setup()
    {
        if (Shader.Find("Hidden/Shader/WaveJitter") != null)
            m_Material = new Material(Shader.Find("Hidden/Shader/WaveJitter"));
    }

    public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle source, RTHandle destination)
    {
        if (m_Material == null)
            return;

        m_Material.SetFloat("_Frequency", _Frequency.value);
        m_Material.SetFloat("_Speed", _Speed.value);
        m_Material.SetFloat("_Amount", _Amount.value);
        m_Material.SetFloat("_RGBSplit", _RGBSplit.value);
        cmd.Blit(source, destination, m_Material, 0);
    }

    public override void Cleanup() => CoreUtils.Destroy(m_Material);
}
