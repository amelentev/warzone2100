uniform mat4 ModelViewProjectionMatrix;
uniform mat4 ModelUVLightmapMatrix;

uniform vec4 cameraPos; // in modelSpace
uniform vec4 sunPos; // in modelSpace, normalized

in vec4 vertex;
in vec2 vertexTexCoord;
in vec3 vertexNormal;
in vec4 vertexTangent; // only for decals
in int tileNo; // positive if decal, negative for old tiles
in uvec4 grounds; // ground types for splatting
in vec4 groundWeights; // ground weights for splatting

out vec2 uvLightmap;
out vec2 uvGround;
out vec2 uvDecal;
out float vertexDistance;
flat out int tile;
flat out uvec4 fgrounds;
out vec4 fgroundWeights;
// In tangent space
out vec3 groundLightDir;
out vec3 groundHalfVec;
out vec3 decalLightDir;
out vec3 decalHalfVec;

void main()
{
	tile = tileNo;

	uvLightmap = (ModelUVLightmapMatrix * vertex).xy;
	uvGround = vec2(-vertex.z, vertex.x);
	uvDecal = vertexTexCoord;

	fgrounds = grounds;
	fgroundWeights = groundWeights;
	if (fgroundWeights == vec4(0)) {
		fgroundWeights = vec4(0.25);
	}

	{ // calc light for ground
		// constructing ModelSpace -> TangentSpace mat3
		vec3 vaxis = vec3(1,0,0); // v ~ vertex.x, see uv_ground
		vec3 tangent = normalize(cross(vertexNormal, vaxis));
		vec3 bitangent = cross(vertexNormal, tangent);
		mat3 ModelTangentMatrix = mat3(tangent, bitangent, vertexNormal); // aka TBN-matrix
		// transform light to TangentSpace:
		vec3 eyeVec = normalize((cameraPos.xyz - vertex.xyz) * ModelTangentMatrix);
		groundLightDir = sunPos.xyz * ModelTangentMatrix; // already normalized
		groundHalfVec = groundLightDir + eyeVec;
	}

	if (tile > 0) { // calc light for decals
		// constructing ModelSpace -> TangentSpace mat3
		vec3 bitangent = -cross(vertexNormal, vertexTangent.xyz) * vertexTangent.w;
		mat3 ModelTangentMatrix = mat3(vertexTangent.xyz, bitangent, vertexNormal);
		// transform light from ModelSpace to TangentSpace:
		vec3 eyeVec = normalize((cameraPos.xyz - vertex.xyz) * ModelTangentMatrix);
		decalLightDir = sunPos.xyz * ModelTangentMatrix;
		decalHalfVec = decalLightDir + eyeVec;
	}

	vec4 position = ModelViewProjectionMatrix * vertex;
	gl_Position = position;
	vertexDistance = position.z;
}
