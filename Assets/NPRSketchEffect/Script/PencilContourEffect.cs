using UnityEngine;

[RequireComponent(typeof(Camera))]
public class PencilContourEffect : MonoBehaviour
{
	public Material m_Mat;
	public Texture2D m_NoiseTex;
	[Range(10f, 50f)] public float m_ErrorPeriod = 25f;
	[Range(0f, 0.005f)] public float m_ErrorRange = 0.0015f;
	[Range(0f, 0.05f)] public float m_NoiseAmount = 0.02f;
	[Range(0f, 1f)] public float m_EdgesOnly = 0f;
	[Range(1f, 5f)] public float m_SampleDistance = 1f;
	public Color m_EdgeColor = Color.black;
	public Color m_BackgroundColor = Color.white;
	int	m_ID_NoiseTex = 0;
	int	m_ID_EdgeOnly = 0;
	int	m_ID_ErrorPeriod = 0;
	int	m_ID_ErrorRange = 0;
	int	m_ID_NoiseAmount = 0;
	int	m_ID_SampleDistance = 0;
	int	m_ID_EdgeColor = 0;
	int	m_ID_BackgroundColor = 0;
	int m_ID_EdgeTex = 0;
	
	void Start()
	{
//		if (SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false)
//			enabled = false;
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;

		m_ID_NoiseTex = Shader.PropertyToID("_NoiseTex");
		m_ID_EdgeOnly = Shader.PropertyToID("_EdgeOnly");
		m_ID_ErrorPeriod = Shader.PropertyToID("_ErrorPeriod");
		m_ID_ErrorRange = Shader.PropertyToID("_ErrorRange");
		m_ID_NoiseAmount = Shader.PropertyToID("_NoiseAmount");
		m_ID_SampleDistance = Shader.PropertyToID("_SampleDistance");
		m_ID_EdgeColor = Shader.PropertyToID("_EdgeColor");
		m_ID_BackgroundColor = Shader.PropertyToID("_BackgroundColor");
		m_ID_EdgeTex = Shader.PropertyToID("_EdgeTex");
	}
	void OnRenderImage(RenderTexture src, RenderTexture dst)
	{
		m_Mat.SetTexture(m_ID_NoiseTex, m_NoiseTex);
		m_Mat.SetFloat(m_ID_EdgeOnly, m_EdgesOnly);
		m_Mat.SetFloat(m_ID_ErrorPeriod, m_ErrorPeriod);
		m_Mat.SetFloat(m_ID_ErrorRange, m_ErrorRange);
		m_Mat.SetFloat(m_ID_NoiseAmount, m_NoiseAmount);
		m_Mat.SetFloat(m_ID_SampleDistance, m_SampleDistance);
		m_Mat.SetColor(m_ID_EdgeColor, m_EdgeColor);
		m_Mat.SetColor(m_ID_BackgroundColor, m_BackgroundColor);

		RenderTexture rt = RenderTexture.GetTemporary(src.width, src.height, 0);
		Graphics.Blit(src, rt, m_Mat, 0);
		m_Mat.SetTexture(m_ID_EdgeTex, rt);
		Graphics.Blit(src, dst, m_Mat, 1);
		RenderTexture.ReleaseTemporary(rt);
	}
}
