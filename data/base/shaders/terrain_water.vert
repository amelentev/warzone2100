// Version directive is set by Warzone when loading the shader
// (This shader supports GLSL 1.20 - 1.50 core.)

uniform mat4 ModelViewProjectionMatrix;
uniform mat3 ModelViewMatrix;
uniform mat3 ModelViewNormalMatrix;
uniform mat4 ModelUV1Matrix;
uniform mat4 ModelUV2Matrix;

uniform float time; // in seconds

uniform vec3 cameraPos; // in modelSpace
uniform vec3 sunPos; // in modelSpace, normalized
uniform vec3 sunPosInView;

#if (!defined(GL_ES) && (__VERSION__ >= 130)) || (defined(GL_ES) && (__VERSION__ >= 300))
in vec4 vertex;
#else
attribute vec4 vertex;
#endif

#if (!defined(GL_ES) && (__VERSION__ >= 130)) || (defined(GL_ES) && (__VERSION__ >= 300))
out vec2 uv1;
out vec2 uv2;
out float vertexDistance;
// light in modelSpace:
out vec3 lightDir;
out vec3 halfVec;
#else
varying vec2 uv1;
varying vec2 uv2;
varying float vertexDistance;
varying vec3 lightDir;
varying vec3 halfVec;
#endif

void main()
{
	vec4 position = ModelViewProjectionMatrix * vertex;
	gl_Position = position;
	vertexDistance = position.z;

	uv1 = vec2(vertex.x/512 + time/10, -vertex.z/512); // (ModelUV1 * vertex).xy;
	uv2 = vec2(vertex.x/1024, -vertex.z/1024); // (ModelUV2 * vertex).xy;

	vec3 eyeVec = normalize(cameraPos - vertex.xyz);
	lightDir = sunPos;
	halfVec = lightDir + eyeVec;
}
