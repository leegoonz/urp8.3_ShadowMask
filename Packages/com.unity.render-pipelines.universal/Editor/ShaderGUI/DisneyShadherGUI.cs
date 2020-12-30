using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;


public class DisneyShaderGUI : ShaderGUI
{
    public enum SurfaceType
    {
        Opaque,
        Transparent,
    }
    public enum BlendType
    {
        OneMinusSrcAlpha,
        Additive
    }
    static bool renderToggle = false;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        Material target = materialEditor.target as Material;
        MaterialProperty surface, zTest, ClipFace, zWrite, blend, alphaCutoffProp;
        renderToggle = EditorGUILayout.Foldout(renderToggle, "Render Options");
        if (renderToggle)
        {
            surface = ShaderGUI.FindProperty("_SurfaceType", properties, true);
            ClipFace = ShaderGUI.FindProperty("_RenderFace", properties, true);
            zWrite = ShaderGUI.FindProperty("_ZWrite", properties, true);
            blend = ShaderGUI.FindProperty("_BlendType", properties, true);
            alphaCutoffProp = FindProperty("_AlphaClipThreshold", properties, true);

            SurfaceType st = (SurfaceType)surface.floatValue;
            EditorGUI.BeginChangeCheck();
            st = (SurfaceType)EditorGUILayout.Popup("Surface Type", (int)st, Enum.GetNames(typeof(SurfaceType)));
            if (EditorGUI.EndChangeCheck())
            {
                surface.floatValue = (float)st;
                foreach (UnityEngine.Object obj in surface.targets)
                    SetupSurfaceType(obj as Material, st);

                if (st == SurfaceType.Transparent)
                {
                    BlendType bt = BlendType.OneMinusSrcAlpha;
                    blend.floatValue = (float)bt;
                    foreach (UnityEngine.Object obj in blend.targets)
                        SetupBlendType(obj as Material, bt);
                    zWrite.floatValue = 0;
                    ClipFace.floatValue = 2;
                }
            }
            if (st == SurfaceType.Transparent)
            {
                EditorGUI.showMixedValue = zWrite.hasMixedValue;
                materialEditor.ShaderProperty(zWrite, "Z Write", 1);
                EditorGUI.showMixedValue = false;

                EditorGUI.showMixedValue = blend.hasMixedValue;
                BlendType bt = (BlendType)blend.floatValue;
                EditorGUI.BeginChangeCheck();
                bt = (BlendType)EditorGUILayout.Popup("Blend Type", (int)bt, Enum.GetNames(typeof(BlendType)));
                if (EditorGUI.EndChangeCheck())
                {
                    blend.floatValue = (float)bt;
                    foreach (UnityEngine.Object obj in blend.targets)
                        SetupBlendType(obj as Material, bt);
                }
                EditorGUI.showMixedValue = false;
            }
            else
                zWrite.floatValue = 1;

            materialEditor.ShaderProperty(ClipFace, "Clip Face");

            bool _AlphaClip_toggle = Array.IndexOf(target.shaderKeywords, "_ALPHATEST_ON") != -1;
            EditorGUI.BeginChangeCheck();
            _AlphaClip_toggle = EditorGUILayout.Toggle("Alpha Clipping", _AlphaClip_toggle);
            if (EditorGUI.EndChangeCheck())
            {
                if (_AlphaClip_toggle) target.EnableKeyword("_ALPHATEST_ON");
                else target.DisableKeyword("_ALPHATEST_ON");
            }
            if (_AlphaClip_toggle)
                materialEditor.ShaderProperty(alphaCutoffProp, "Threshold", 1);

        }
        base.OnGUI(materialEditor, properties);
    }

    private void SetupSurfaceType(Material material, SurfaceType st)
    {
        switch (st)
        {
            case SurfaceType.Opaque:
                material.SetFloat("_SrcBlend", (float)UnityEngine.Rendering.BlendMode.One);
                material.SetFloat("_DstBlend", (float)UnityEngine.Rendering.BlendMode.Zero);
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Geometry;
                material.SetShaderPassEnabled("ShadowCaster", true);
                break;
            case SurfaceType.Transparent:

                material.SetFloat("_SrcBlend", (float)UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetFloat("_DstBlend", (float)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                material.SetShaderPassEnabled("ShadowCaster", false);
                break;
        }
    }

    private void SetupBlendType(Material material, BlendType bt)
    {
        switch (bt)
        {
            case BlendType.OneMinusSrcAlpha:
                material.SetFloat("_SrcBlend", (float)UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetFloat("_DstBlend", (float)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                break;
            case BlendType.Additive:
                material.SetFloat("_SrcBlend", (float)UnityEngine.Rendering.BlendMode.One);
                material.SetFloat("_DstBlend", (float)UnityEngine.Rendering.BlendMode.One);
                break;
        }
    }

    static bool Foldout(bool display, string title)
    {
        var style = new GUIStyle("ShurikenModuleTitle");
        style.font = new GUIStyle(EditorStyles.boldLabel).font;
        style.fontSize = 12;
        style.border = new RectOffset(15, 7, 4, 4);
        style.fixedHeight = 26;
        style.contentOffset = new Vector2(20f, -2f);

        var rect = GUILayoutUtility.GetRect(16f, 22f, style);
        GUI.Box(rect, title, style);

        var e = Event.current;

        var toggleRect = new Rect(rect.x + 4f, rect.y + 2f, 13f, 13f);
        if (e.type == EventType.Repaint)
        {
            EditorStyles.foldout.Draw(toggleRect, false, false, display, false);
        }

        if (e.type == EventType.MouseDown && rect.Contains(e.mousePosition))
        {
            display = !display;
            e.Use();
        }

        return display;
    }
}




