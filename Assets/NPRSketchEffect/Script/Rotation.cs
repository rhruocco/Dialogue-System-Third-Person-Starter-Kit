using UnityEngine;

public class Rotation : MonoBehaviour
{
	public float m_Speed = 100f;
	public bool m_RotX = false;
	public bool m_RotY = false;
	public bool m_RotZ = false;

	void Update()
	{
		if (m_RotX)
			transform.Rotate(m_Speed * Time.deltaTime, 0, 0);
		if (m_RotY)
			transform.Rotate(0, m_Speed * Time.deltaTime, 0);
		if (m_RotZ)
			transform.Rotate(0, 0, m_Speed * Time.deltaTime);
	}
}