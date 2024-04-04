using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;



[CreateAssetMenu(fileName = "HairNoise", menuName = "HairNoise", order = 1)]
public class HairNoise : ScriptableObject { 
    public SinParams[] sinParams;
    public AnimationCurve noiseCurve;
    private Keyframe[] keys;
    public float getNoise(float x) {
        float noise = 0;
        foreach (SinParams sinParam in sinParams) {
            noise += sinParam.getSin(x);
        }
        return noise;
    }
    public void UpdateCurve() { 
        float step = 0.01f;
        float max = 0;
        keys = new Keyframe[1000];
        foreach (SinParams sinParam in sinParams) {
            max += sinParam.amplitude;
        }
        for (int i = 0; i < 1000; i++) {
            float x = i * step;
            float y = getNoise(x);
            keys[i] = new Keyframe(x, 10 * (y + max)/(2*max));
        }
        noiseCurve = new AnimationCurve(keys);
    }
    [ContextMenu("UpdateTex")]
    public void UpdateTex() {
        UpdateCurve();
        Texture2D texture = new Texture2D(1000, 1000);
        for (int i = 0; i < 1000; i++) {
            for (int j = 0; j < 1000; j++) {
                texture.SetPixel(i,j,Color.white * (noiseCurve.Evaluate(i/100f)/10f));
            }
        }
        byte[] bytes = texture.EncodeToPNG();
        System.IO.File.WriteAllBytes("Assets/Hair/NoiseMap.png", bytes);
    }
    [ContextMenu("RandomArrange")]
    public void RandomArrange() {
        foreach (SinParams sinParam in sinParams) {
            sinParam.amplitude = UnityEngine.Random.Range(0f,10f);
            sinParam.frequency = UnityEngine.Random.Range(0f,10f);
            sinParam.phase = UnityEngine.Random.Range(0f,10f);
        }
        UpdateCurve();
    }
    public void OnValidate() {
        UpdateCurve();
    }
}

[Serializable]
public class SinParams {
    [Range(0, 10)]
    public float amplitude;
    [Range(0, 10)]
    public float frequency;
    [Range(0, 10)]
    public float phase;
    public float getSin(float x) {
        return amplitude * Mathf.Sin(frequency * x + phase);
    }

}

