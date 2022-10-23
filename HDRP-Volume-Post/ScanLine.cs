using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using System;

[Serializable, VolumeComponentMenu("Post-processing/Custom/ScanLine")]
public sealed class ScanLine : CustomPostProcessVolumeComponent, IPostProcessComponent
{
    [Tooltip("Controls the intensity of the effect.")]
    public ClampedFloatParameter _Radius = new ClampedFloatParameter(0f, 0f, 1.0f);
    public ClampedFloatParameter _Width = new ClampedFloatParameter(0f, 0.001f, 0.1f);
    public Vector4Parameter _Center = new Vector4Parameter(new Vector4(0,0,0,0));
    public ColorParameter _Color = new ColorParameter(Color.white);
    public ColorParameter _Color_End = new ColorParameter(Color.white);

    Material m_Material;

    public bool IsActive() => m_Material != null && active && _Radius.value > 0;

    public override CustomPostProcessInjectionPoint injectionPoint => CustomPostProcessInjectionPoint.AfterPostProcess;

    public override void Setup()
    {
        if (Shader.Find("Hidden/Shader/ScanLine") != null)
            m_Material = new Material(Shader.Find("Hidden/Shader/ScanLine"));
    }

    public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle source, RTHandle destination)
    {
        if (m_Material == null)
            return;

        m_Material.SetFloat("_Radius", _Radius.value);
        m_Material.SetFloat("_Width", _Width.value);
        m_Material.SetVector("_Center", _Center.value);
        m_Material.SetColor("_Color", _Color.value);
        m_Material.SetColor("_Color_End", _Color_End.value);
        cmd.Blit(source, destination, m_Material, 0);
    }

    public override void Cleanup() => CoreUtils.Destroy(m_Material);

}