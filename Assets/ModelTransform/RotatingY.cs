using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotatingY : MonoBehaviour
{
    // ranged variable
    [Range(0.0f, 1.0f)]
    public float rotationSpeed = 0.2f;
    // Start is called before the first frame update
    void Start()
    {
        Transform transform = GetComponent<Transform>();
    }

    // Update is called once per frame
    void Update()
    {
        // slowly rotate the object
        transform.Rotate(0, rotationSpeed, 0);
    }
}
