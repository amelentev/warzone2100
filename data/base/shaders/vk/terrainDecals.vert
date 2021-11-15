#version 450

#include "terrainDecals.glsl"

layout(location = 0) in vec4 vertex;
layout(location = 1) in vec2 vertexTexCoord;
layout(location = 3) in vec3 vertexNormal;
layout(location = 4) in vec4 vertexTangent;	// for decals
layout(location = 5) in int tileNo;
layout(location = 6) in uvec4 grounds;		// ground types for splatting
layout(location = 7) in vec4 groundWeights;	// ground weights for splatting

layout(location = 0) out FragData frag;
layout(location = 9) out flat FragFlatData fragf;

void main()
{
	fragf.tileNo = tileNo;

	frag.uvLightmap = (ModelUVLightmapMatrix * vertex).xy;
	frag.uvGround = vec2(-vertex.z, vertex.x);
	frag.uvDecal = vertexTexCoord;

	fragf.grounds = grounds;
	if (groundWeights == vec4(0)) {
		frag.groundWeights = vec4(0.25);
	} else {
		frag.groundWeights = groundWeights;
	}

	{ // calc light for ground
		// constructing ModelSpace -> TangentSpace mat3
		vec3 vaxis = vec3(1,0,0); // v ~ vertex.x, see uv_ground
		vec3 tangent = normalize(cross(vertexNormal, vaxis));
		vec3 bitangent = cross(vertexNormal, tangent);
		mat3 ModelTangentMatrix = mat3(tangent, bitangent, vertexNormal); // aka TBN-matrix
		// transform light to TangentSpace:
		vec3 eyeVec = normalize((cameraPos.xyz - vertex.xyz) * ModelTangentMatrix);
		frag.groundLightDir = sunPos.xyz * ModelTangentMatrix; // already normalized
		frag.groundHalfVec = frag.groundLightDir + eyeVec;
	}

	if (tileNo > 0) { // calc light for decals
		// constructing ModelSpace -> TangentSpace mat3
		vec3 bitangent = -cross(vertexNormal, vertexTangent.xyz) * vertexTangent.w;
		mat3 ModelTangentMatrix = mat3(vertexTangent.xyz, bitangent, vertexNormal);
		// transform light from ModelSpace to TangentSpace:
		vec3 eyeVec = normalize((cameraPos.xyz - vertex.xyz) * ModelTangentMatrix);
		frag.decalLightDir = sunPos.xyz * ModelTangentMatrix;
		frag.decalHalfVec = frag.decalLightDir + eyeVec;
	}

	vec4 position = ModelViewProjectionMatrix * vertex;
	frag.vertexDistance = position.z;
	gl_Position = position;
	gl_Position.y *= -1.;
	gl_Position.z = (gl_Position.z + gl_Position.w) / 2.0;
}
