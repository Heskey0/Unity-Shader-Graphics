using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

// Referrence:: https://zhuanlan.zhihu.com/p/493802718
public class NormalTool : MonoBehaviour
{
    [MenuItem("Tools/Model/模型平均法线写入顶点色，并创建资产")]
    public static void WriteAverageNormalToTangentTool()
    {
        MeshFilter[] meshFilters = Selection.activeGameObject.GetComponentsInChildren<MeshFilter>();
        foreach (var meshFilter in meshFilters)
        {
            Mesh mesh = Object.Instantiate(meshFilter.sharedMesh);
            WriteAverageNormalToTangent(mesh);
            CreateTangentMesh(mesh,meshFilter);
        }
        
        SkinnedMeshRenderer[] skinnedMeshRenders = Selection.activeGameObject.GetComponentsInChildren<SkinnedMeshRenderer>();
        foreach (var skinnedMeshRender in skinnedMeshRenders)
        {
            Mesh mesh = Object.Instantiate(skinnedMeshRender.sharedMesh);
            WriteAverageNormalToTangent(mesh);
            CreateTangentMesh(mesh, skinnedMeshRender);
        }
    }
    private static void WriteAverageNormalToTangent(Mesh rMesh)
    {
        Dictionary<Vector3, Vector3> tAverageNormalDic = new Dictionary<Vector3, Vector3>();
        for (int i = 0; i < rMesh.vertexCount; i++)
        {
            if (!tAverageNormalDic.ContainsKey(rMesh.vertices[i]))
            {
                tAverageNormalDic.Add(rMesh.vertices[i], rMesh.normals[i]);
            }
            else
            {
                //对当前顶点的所有法线进行平滑处理
                tAverageNormalDic[rMesh.vertices[i]] = (tAverageNormalDic[rMesh.vertices[i]] + rMesh.normals[i]).normalized;
            }
        }

        Vector3[] tAverageNormals = new Vector3[rMesh.vertexCount];
        for (int i = 0; i < rMesh.vertexCount; i++)
        {
            tAverageNormals[i] = tAverageNormalDic[rMesh.vertices[i]];
        }
        
        //Vector4[] tTangents = new Vector4[rMesh.vertexCount];
        Color[] tColors = new Color[rMesh.vertexCount];
        for (int i = 0; i < rMesh.vertexCount; i++)
        {
            //tTangents[i] = new Vector4(tAverageNormals[i].x,tAverageNormals[i].y,tAverageNormals[i].z,0);
            tColors[i] = new Color(tAverageNormals[i].x, tAverageNormals[i].y, tAverageNormals[i].z, 0);
        }

        rMesh.colors = tColors;
        //rMesh.tangents = tTangents;
    }
    
    //在当前路径创建切线模型
    private static void CreateTangentMesh(Mesh rMesh, SkinnedMeshRenderer rSkinMeshRenders)
    {
        string[] path = AssetDatabase.GetAssetPath(rSkinMeshRenders).Split("/");
        string createPath = "";
        for (int i = 0; i < path.Length - 1; i++)
        {
            createPath += path[i] + "/";
        }
        string newMeshPath = createPath + rSkinMeshRenders.name + "_Tangent.mesh";
        Debug.Log("存储模型位置：" + newMeshPath);
        AssetDatabase.CreateAsset(rMesh, newMeshPath);
    }
    //在当前路径创建切线模型
    private static void CreateTangentMesh(Mesh rMesh, MeshFilter rMeshFilter)
    {
        string[] path = AssetDatabase.GetAssetPath(rMeshFilter).Split("/");
        string createPath = "";
        for (int i = 0; i < path.Length - 1; i++)
        {
            createPath += path[i] + "/";
        }
        string newMeshPath = createPath + rMeshFilter.name + "_Tangent.mesh";
        //rMeshFilter.mesh.colors = rMesh.colors;
        Debug.Log("存储模型位置：" + newMeshPath);
        AssetDatabase.CreateAsset(rMesh, newMeshPath);
    }
}
