using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;


public abstract class PostVolumeComponentBase : VolumeComponent, IPostProcessComponent, IDisposable
{

    public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
    
    
    /// 初始化，将在RenderPass加入队列时调用
    public abstract void Setup();

    /// 执行渲染
    public abstract void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source, RenderTargetIdentifier destination);

    #region IPostProcessComponent
    /// 返回当前组件是否处于激活状态
    public abstract bool IsActive();

    public virtual bool IsTileCompatible() => false;
    #endregion
    
    #region IDisposable
    public void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }

    /// 释放资源
    public virtual void Dispose(bool disposing) {}
    #endregion
}
