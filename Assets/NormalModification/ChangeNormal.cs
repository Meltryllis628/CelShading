using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.UIElements;

public class ChangeNormal : MonoBehaviour {
    public Vector3 CenterOffset = new Vector3(0, 0, 0);
    Mesh MeshNormalSmooth(Mesh mesh) {
        Vector3[] vertices = mesh.vertices;
        Vector3 center = new Vector3(0, 0, 0);
        for (int i = 0; i < vertices.Length; i++) {
            center += vertices[i];
        }
        center /= vertices.Length;
        center += CenterOffset;
        Vector3[] newNormals = new Vector3[vertices.Length];
        for (int i = 0; i < vertices.Length; i++) {
            newNormals[i] = ((vertices[i].x - center.x) * Vector3.right + (vertices[i].z - center.z) * Vector3.forward).normalized;
        }
        mesh.normals = newNormals;
        return mesh;
    }
    private void Awake() {
        if (GetComponent<MeshFilter>()) {
            Mesh tempMesh = (Mesh)Instantiate(GetComponent<MeshFilter>().sharedMesh);
            tempMesh = MeshNormalSmooth(tempMesh);
            gameObject.GetComponent<MeshFilter>().sharedMesh = tempMesh;
        }
        if (GetComponent<SkinnedMeshRenderer>()) {
            Mesh tempMesh = (Mesh)Instantiate(GetComponent<SkinnedMeshRenderer>().sharedMesh);
            tempMesh = MeshNormalSmooth(tempMesh);
            gameObject.GetComponent<SkinnedMeshRenderer>().sharedMesh = tempMesh;
        }
    }
}
