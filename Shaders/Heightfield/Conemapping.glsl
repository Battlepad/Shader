#define PI 3.1459
#define RAD PI / 180.0

uniform vec3 iMouse;
uniform vec2 iResolution;
uniform float iGlobalTime;
uniform sampler2D tex;
varying vec2 uv;
//uniform vec3[4096][2048] multidim;

// vec3 applyFog( in vec3  rgb,       // original color of the pixel
//                in float distance ) // camera to point distance
// {
//     float fogAmount = 1.0 - exp( -distance*b );
//     vec3  fogColor  = vec3(0.5,0.6,0.7);
//     return mix( rgb, fogColor, fogAmount );
// }

struct Intersection
{
	vec3 intersectP;
	vec4 color;
	vec3 normal;
	bool exists;
};

mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                               	0.0,                                0.0,                                1.0);
}
vec3 opTx( vec3 p, mat4 m )
{
    vec3 q = inverse(m)*vec4(p,1.0);
    return q;
}

//float f(float x, float y)
//{
//	return texture(tex, vec2(x,y)/textureSize).x*1.0;
//}


Intersection rayMarch(vec3 origin, vec3 direction, float beginEpsilon)
{
	Intersection intersect;
	intersect.exists = false;

	vec3 newPos = origin;
	
	newPos += beginEpsilon*direction; //set nearer pos, when terrain is far below the cam

	for(int i = -85; i <= -45; i=i+5)
	{
		// Intersection r1 = rayMarch(origin, (rotationMatrix(vec3(1.0,0.0,1.0), i * RAD) * vec4(1.0,0.0,0.0,1.0)).xyz;)
		// Intersection r2 = rayMarch(origin, (rotationMatrix(vec3(1.0,0.0,1.0), i * RAD) * vec4(-1.0,0.0,0.0,1.0)).xyz;)
		// Intersection r3 = rayMarch(origin, (rotationMatrix(vec3(1.0,0.0,1.0), i * RAD) * vec4(0.0,0.0,1.0,1.0)).xyz;)
		// Intersection r4 = rayMarch(origin, (rotationMatrix(vec3(1.0,0.0,1.0), i * RAD) * vec4(0.0,0.0,-1.0,1.0)).xyz;)
		// Intersection r5 = rayMarch(origin, (rotationMatrix(vec3(1.0,0.0,1.0), i * RAD) * vec4(1.0,0.0,1.0,1.0)).xyz;)
		// Intersection r6 = rayMarch(origin, (rotationMatrix(vec3(1.0,0.0,1.0), i * RAD) * vec4(1.0,0.0,-1.0,1.0)).xyz;)
		// Intersection r7 = rayMarch(origin, (rotationMatrix(vec3(1.0,0.0,1.0), i * RAD) * vec4(-1.0,0.0,-1.0,1.0)).xyz;)
		// Intersection r8 = rayMarch(origin, (rotationMatrix(vec3(1.0,0.0,1.0), i * RAD) * vec4(-1.0,0.0,1.0,1.0)).xyz;)

		// if(r1.exists)
		// {
			
		// }

		//float height = f(newPos.x, newPos.z);

	}
	intersect.intersectP = newPos;
	intersect.color = vec4(0.0,0.0,0.0,0.0);
	return intersect;
}

float CalcAngle(vec2 _uv)
{
	float angle = 0.0;
	float angleNew = 0.0;

	for(int y=0; y<iResolution.y; y++)
	{
		for(int x=0; x<iResolution.x; x++)
		{
			float hypothenuse = length(vec2(x,y)/iResolution.xy - _uv.xy);
			float height = (vec2(x,y)/iResolution.xy).r - texture(tex, _uv).r; 
			float b_div_c = height / hypothenuse;
			angleNew = asin(b_div_c);
			if(angleNew > angle)
			{
				angle = angleNew;
			}
		}
	}
	return 90.0-(angle*(180.0/(2.0*PI)));
}

void main()
{
	float fov = 70.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

	vec3 camP = vec3(50.0, 1.5, 20.0+iGlobalTime/2);//vec3(15.0, abs(sin(iGlobalTime))*5+5.0, 0.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));

	//Intersection intersect = rayMarch(camP, camDir, 1.0);
	float angleFin = CalcAngle(uv);
	vec3 color = texture(tex, uv).rgb;
	int divisor = 180;
	gl_FragColor = vec4(angleFin/divisor, texture(tex, uv).x, 1.0, 1.0);
	//if(intersect.exists)
	//{
		//gl_FragColor = intersect.color;
	//}		
	//else
		//gl_FragColor = fogColor;
}		