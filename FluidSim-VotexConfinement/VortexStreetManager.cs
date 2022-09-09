using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class VortexStreetManager : MonoBehaviour
{
    public Material DivergenceMat;
    public Material PressureMat;
    public Material SubtractMat;
    public Material AdvectionVelocityMat;
    public Material BlockMat;
    public Material DisplayRainbowMat;
    public Material VorticityMat;
    public Material VorticityConfineMat;
    private int TexWidth = Screen.width;
    private int TexHeight = Screen.height;

    private RenderTexture VorticityRT;
    private RenderTexture DivergenceRT;
    private RenderTexture DyeRT;
    private RenderTexture DyeRT2;
    private RenderTexture VelocityRT;
    private RenderTexture VelocityRT2;
    private RenderTexture PressureRT;
    private RenderTexture PressureRT2;
    private RenderTexture InitDyeRT;
    private RenderTexture BlockRT;
    

    public float dt = 0.01f;
    public float curl_strength = 0;

    private void Awake()
    {
        Application.targetFrameRate = 60;
    }

    void Start()
    {
        DivergenceRT = new RenderTexture(TexWidth, TexHeight, 0, RenderTextureFormat.RHalf); DivergenceRT.Create();
        VelocityRT = new RenderTexture(TexWidth, TexHeight, 0, RenderTextureFormat.RGHalf); VelocityRT.Create();
        VelocityRT2 = new RenderTexture(TexWidth, TexHeight, 0, RenderTextureFormat.RGHalf); VelocityRT2.Create();
        PressureRT = new RenderTexture(TexWidth, TexHeight, 0, RenderTextureFormat.RHalf); PressureRT.Create();
        PressureRT2 = new RenderTexture(TexWidth, TexHeight, 0, RenderTextureFormat.RHalf); PressureRT2.Create();
        BlockRT = new RenderTexture(TexWidth, TexHeight, 0, RenderTextureFormat.ARGBHalf); BlockRT.Create();
        VorticityRT = new RenderTexture(TexWidth, TexHeight, 0, RenderTextureFormat.ARGBHalf); VorticityRT.Create();
        
        DivergenceRT.filterMode = FilterMode.Bilinear;
        VelocityRT.filterMode = FilterMode.Bilinear;
        VelocityRT2.filterMode = FilterMode.Bilinear;
        PressureRT.filterMode = FilterMode.Bilinear;
        PressureRT2.filterMode = FilterMode.Bilinear;
        BlockRT.filterMode = FilterMode.Bilinear;
        VorticityRT.filterMode = FilterMode.Bilinear;

        PressureRT.wrapMode = TextureWrapMode.Clamp;
        PressureRT2.wrapMode = TextureWrapMode.Clamp;
        VorticityRT.wrapMode = TextureWrapMode.Clamp;
        
        Graphics.Blit(null, BlockRT, BlockMat);
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // Step 1: Advection
            // sub-step 1.1: advect the velocity field
        AdvectionVelocityMat.SetTexture("VelocityTex", VelocityRT2);
        AdvectionVelocityMat.SetTexture("BlockTex", BlockRT);
        AdvectionVelocityMat.SetTexture("QuantityTex", VelocityRT2);
        AdvectionVelocityMat.SetFloat("dt", dt);
        Graphics.Blit(VelocityRT2, VelocityRT, AdvectionVelocityMat);
        
            // sub-step 1.2: advect the dye field
            // TODO:
            // sub-step 1.3: swap
        Graphics.Blit(VelocityRT, VelocityRT2);
        
        // Step 2: Add body forces
        // for smoke, ignore the gravity force
        // for water, ignore the viscose force

        // Step 3: Compute Divergence
        DivergenceMat.SetTexture("VelocityTex", VelocityRT2);
        Graphics.Blit(VelocityRT2, DivergenceRT, DivergenceMat);

        // Step 4: Vorticity Confinement
            // sub-step 4.1: compute vorticity
        VorticityMat.SetTexture("VelocityTex", VelocityRT2);
        Graphics.Blit(VelocityRT2, VorticityRT, VorticityMat);
            // sub-step 4.2: update velocity field
        VorticityConfineMat.SetTexture("VelocityTex", VelocityRT2);
        VorticityConfineMat.SetTexture("VorticityTex", VorticityRT);
        VorticityConfineMat.SetFloat("curl_strength", curl_strength);
        VorticityConfineMat.SetFloat("dt", dt);
        Graphics.Blit(VelocityRT2, VelocityRT, VorticityConfineMat);
        Graphics.Blit(VelocityRT, VelocityRT2);
            
        // Step 5: Solve poisson's equation: Ap=d
        PressureMat.SetTexture("DivergenceTex", DivergenceRT);
        for (int i = 0; i < 100; i++)
        {
            PressureMat.SetTexture("PressureTex", PressureRT2);
            Graphics.Blit(PressureRT2, PressureRT, PressureMat);
            Graphics.Blit(PressureRT, PressureRT2);
        }
        
        // Step 6: Projection (divergence-free flow)
        SubtractMat.SetTexture("PressureTex", PressureRT2);
        SubtractMat.SetTexture("VelocityTex", VelocityRT2);
        SubtractMat.SetFloat("dt", dt);
        Graphics.Blit(VelocityRT2, VelocityRT, SubtractMat);
        Graphics.Blit(VelocityRT, VelocityRT2);


        // Step 7: Display
        DisplayRainbowMat.SetTexture("BlockTex", BlockRT);
        Graphics.Blit(VelocityRT2, destination, DisplayRainbowMat);
        //Graphics.Blit(PressureRT2, destination, DisplayRainbowMat);
    }
}
