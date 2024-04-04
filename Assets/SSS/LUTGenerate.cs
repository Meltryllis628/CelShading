using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;
using static UnityEditor.UIElements.ToolbarMenu;
[CreateAssetMenu(fileName = "LUTGenerate", menuName = "LUTGenerate", order = 1)]
public class LUTGenerate : ScriptableObject {
    public AnimationCurve SSCurve;
    public AnimationCurve SigmoidDark;
    public AnimationCurve SigmoidMid;
    public AnimationCurve GaussionDark;
    public AnimationCurve GaussionMid;
    public Color SSSColor = new Color(1, 0, 0, 1);
    [Range(0, 1)]
    public float SSSStrength = 0.5f;
    [Range(0, 1)]
    public float SSSSize = 0.5f;
    [Range(0, 1)]
    public float SSForwardAtt = 0.5f;
    [Range(-1, 1)]
    public float DividLineM = 0;
    [Range(-1, 1)]
    public float DividLineD = -0.5f;
    [Range(0.2f, 5)]
    public float DividSharpness = 1.0f;
    float Gaussion(float x, float Center, float Variance) {
        return (float)Math.Pow(Math.E, -1 * Math.Pow(2, x - Center) / Variance);
    }
    float Sigmoid(float x, float center, float sharp) {
        return 1 / (1 + (float)Math.Pow(100000, -3 * sharp * (x - center)));
    }
    [ContextMenu("GenerateLUT")]
    public void GenerateLUT() {
        UpdateCurve();
        Texture2D LUT = new Texture2D(256, 256, TextureFormat.RGBA32, false);
        LUT.filterMode = FilterMode.Bilinear;
        LUT.wrapMode = TextureWrapMode.Clamp;
        for (int i = 0; i < 256; i++) {
            float NdotL = i / 128f - 1f;
            float SS = SSCurve.Evaluate(NdotL);
            Color output = new Color(SS*SSSColor.r, SS*SSSColor.g, SS*SSSColor.b, 1f);
            for (int j = 0; j < 256; j++) {
                LUT.SetPixel(i, j, output);
            }
        }
        LUT.Apply();
        byte[] bytes = LUT.EncodeToPNG();
        System.IO.File.WriteAllBytes("Assets/SSS/LUT.png", bytes);
    }
    public void UpdateCurve() {
        SSCurve = new AnimationCurve();
        SigmoidDark = new AnimationCurve();
        SigmoidMid = new AnimationCurve();
        GaussionDark = new AnimationCurve();
        GaussionMid = new AnimationCurve();
        for (int i = 0; i < 256; i++) {
            float x = i / 128f - 1f;
            float SSMidLWin = Gaussion(x, DividLineM, SSForwardAtt * SSSSize);
            float SSMidDWin = Gaussion(x, DividLineM, SSSSize);

            float SSMidLWinSub = Gaussion(x, DividLineM, SSForwardAtt * SSSSize * 0.01f);
            float SSMidDWinSub = Gaussion(x, DividLineM, SSSSize * 0.01f);

            float MidSig = Sigmoid(x, DividLineM, DividSharpness);
            float DarkSig = Sigmoid(x, DividLineD, DividSharpness);


            float diffuseLumin = (DividLineM + DividLineD) * 0.5f + 1f;

            float SSLumin1 = MidSig * diffuseLumin * SSForwardAtt * (SSMidLWin + SSMidLWinSub);
            float SSLumin2 = DarkSig * diffuseLumin * (SSMidDWin + SSMidDWinSub);

            float SS = SSSStrength * (SSLumin1 + SSLumin2);
            SSCurve.AddKey(x, SS);
            SigmoidDark.AddKey(x, DarkSig);
            SigmoidMid.AddKey(x, MidSig);
            GaussionDark.AddKey(x, SSLumin2);
            GaussionMid.AddKey(x, SSLumin1);
        }
    }


    public void OnValidate() {
        UpdateCurve();
    }
}

