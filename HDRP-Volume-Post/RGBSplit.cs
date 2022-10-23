using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using System;

[Serializable, VolumeComponentMenu("Post-processing/Custom/RGBSplit")]
public sealed class RGBSplit : CustomPostProcessVolumeComponent, IPostProcessComponent
{
    //float _Frequency;
    //float _Speed;
    //float _Amount;
    //float _RGBSplit;
    
    [Tooltip("Controls the intensity of the effect.")]
    public ClampedFloatParameter _Intensity = new ClampedFloatParameter(0f, 0f, 0.3f);


    Material m_Material;

    public bool IsActive() => m_Material != null && _Intensity.value > 0f && active;

    public override CustomPostProcessInjectionPoint injectionPoint => CustomPostProcessInjectionPoint.AfterPostProcess;

    public override void Setup()
    {
        if (Shader.Find("Hidden/Shader/RGBSplit") != null)
            m_Material = new Material(Shader.Find("Hidden/Shader/RGBSplit"));
    }

    public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle source, RTHandle destination)
    {
        if (m_Material == null)
            return;

        m_Material.SetFloat("_Intensity", _Intensity.value);
        cmd.Blit(source, destination, m_Material, 0);
    }

    public override void Cleanup() => CoreUtils.Destroy(m_Material);
}
