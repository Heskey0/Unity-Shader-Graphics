using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CloudManager : MonoBehaviour
{
    public Material M_CloudMarching;

    private RenderTexture RT_marchingResult;
    
    private int TexWidth = Screen.width;
    private int TexHeight = Screen.height;
    
    private void Awake()
    {
        Application.targetFrameRate = 60;
    }
    
    // Start is called before the first frame update
    void Start()
    {
        RT_marchingResult = new RenderTexture(TexWidth, TexHeight, 0, RenderTextureFormat.ARGBHalf);
        RT_marchingResult.Create();
    }

    // Update is called once per frame
    void Update()
    {
        
    }
    
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (Input.GetKey(KeyCode.N))
        {
            Graphics.Blit(null, RT_marchingResult, M_CloudMarching);
        }
        Graphics.Blit(RT_marchingResult, dest);
    }
}
