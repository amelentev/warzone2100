#version 450

#include "terrainDecals.glsl"

layout(set = 1, binding = 0) uniform sampler2D lightmap_tex;

// ground texture arrays. layer = ground type
layout(set = 1, binding = 1) uniform sampler2DArray groundTex;
layout(set = 1, binding = 2) uniform sampler2DArray groundNormal;
layout(set = 1, binding = 3) uniform sampler2DArray groundSpecular;
layout(set = 1, binding = 4) uniform sampler2DArray groundHeight;

// decal texture arrays. layer = decal tile
layout(set = 1, binding = 5) uniform sampler2DArray decalTex;
layout(set = 1, binding = 6) uniform sampler2DArray decalNormal;
layout(set = 1, binding = 7) uniform sampler2DArray decalSpecular;
layout(set = 1, binding = 8) uniform sampler2DArray decalHeight;

layout(location = 0) in FragData frag;
layout(location = 9) flat in FragFlatData fragf;

layout(location = 0) out vec4 FragColor;

vec3 getGroundUv(int i) {
	uint groundNo = fragf.grounds[i];
	return vec3(frag.uvGround * groundScale[groundNo/4u][groundNo%4u], groundNo);
}

vec3 getGround(int i) {
	return texture(groundTex, getGroundUv(i)).rgb * frag.groundWeights[i];
}

vec4 main_classic() {
	vec3 ground = getGround(0) + getGround(1) + getGround(2) + getGround(3);
	vec4 decal = fragf.tileNo > 0 ? texture(decalTex, vec3(frag.uvDecal, fragf.tileNo)) : vec4(0);
	vec4 light = texture(lightmap_tex, frag.uvLightmap);
	return light * vec4((1-decal.a) * ground + decal.a * decal.rgb, 1);
}

struct BumpData {
	vec4 color;
	vec3 N;
	float gloss;
};

void getGroundBM(int i, inout BumpData res) {
	vec3 uv = getGroundUv(i);
	float w = frag.groundWeights[i];
	res.color += texture(groundTex, uv) * w;
	vec3 N = texture(groundNormal, uv).xyz;
	if (N == vec3(0)) {
		N = vec3(0,0,1);
	} else {
		N = normalize(N * 2 - 1);
	}
	res.N += N * w;
	res.gloss += texture(groundSpecular, uv).r * w;
}

vec4 doBumpMapping(BumpData b, vec3 lightDir, vec3 halfVec) {
	vec3 L = normalize(lightDir);
	float lambertTerm = max(dot(b.N, L), 0.0); // diffuse lighting
	// Gaussian specular term computation
	vec3 H = normalize(halfVec);
	float exponent = acos(dot(H, b.N)) / 0.5;
	float gaussianTerm = exp(-(exponent * exponent)) * float(lambertTerm > 0);

	vec4 res = b.color*(ambientLight*0.5 + diffuseLight*lambertTerm) + specularLight*b.gloss*gaussianTerm;
	return vec4(res.rgb, b.color.a);
}

vec4 main_bumpMapping() {
	BumpData groundData;
	groundData.color = vec4(0);
	groundData.N = vec3(0,0,0);
	groundData.gloss = 0.0;
	getGroundBM(0, groundData);
	getGroundBM(1, groundData);
	getGroundBM(2, groundData);
	getGroundBM(3, groundData);
	vec3 ground = doBumpMapping(groundData, frag.groundLightDir, frag.groundHalfVec).rgb;

	vec4 decal;
	if (fragf.tileNo > 0) {
		BumpData decalData;
		vec3 uv = vec3(frag.uvDecal, fragf.tileNo);
		decalData.color = texture(decalTex, uv);
		decalData.N = texture(decalNormal, uv).xyz;
		if (decalData.N == vec3(0)) {
			decalData.N = vec3(0,0,1);
		} else {
			decalData.N = normalize(decalData.N * 2 - 1);
		}
		decalData.gloss = texture(decalSpecular, uv).r;
		decal = doBumpMapping(decalData, frag.decalLightDir, frag.decalHalfVec);
	} else {
		decal = vec4(0);
	}
	vec4 lightMask = texture(lightmap_tex, frag.uvLightmap);
	return lightMask * vec4((1-decal.a) * ground + decal.a * decal.rgb, 1);
}

void main()
{
	vec4 fragColor;
	if (quality == 1) {
		fragColor = main_bumpMapping();
	} else {
		fragColor = main_classic();
	}

	if (fogEnabled > 0)
	{
		// Calculate linear fog
		float fogFactor = (fogEnd - frag.vertexDistance) / (fogEnd - fogStart);
		fogFactor = clamp(fogFactor, 0.0, 1.0);

		// Return fragment color
		fragColor = mix(fragColor, vec4(fogColor.xyz, fragColor.w), fogFactor);
	}
	FragColor = fragColor;
}
