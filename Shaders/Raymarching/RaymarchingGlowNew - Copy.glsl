uniform vec3 iMouse;
uniform vec2 iResolution;
uniform float iGlobalTime;
varying vec2 uv;

float time=iGlobalTime;

const float epsilon = 0.001;
const float glowEpsilon = 0.18;
const int maxIterations = 96;



// vec3 applyFog( in vec3  rgb,       // original color of the pixel
//                in float distance ) // camera to point distance
// {
//     float fogAmount = 1.0 - exp( -distance*b );
//     vec3  fogColor  = vec3(0.5,0.6,0.7);
//     return mix( rgb, fogColor, fogAmount );
// }

vec3 repeat(vec3 P, vec3 b) //P ist Punkt wo man mit Marching gerade ist
{
	return mod(P,b)-1.0/2.0*b;
}

float distSphere(vec3 origin, vec3 middle, float r)
{
    return length(origin - middle) - r;
}

float distance(vec3 point)
{
	vec3 spherePos = vec3(0.0,0.0,0.0);
	float radius = 0.400;
	vec3 b = vec3(4.0,4.0,8.0);
	point = repeat(point, b);
	return distSphere(point, spherePos, radius);
}

vec3 getNormal(vec3 point)
{
	//grad of the vector (= normal)
	return vec3(distance(point + vec3(epsilon,0.0,0.0)) - distance(point + vec3(-epsilon,0.0,0.0)),
				distance(point + vec3(0.0,epsilon,0.0)) - distance(point + vec3(0.0,-epsilon,0.0)),
				distance(point + vec3(0.0,0.0,epsilon)) - distance(point + vec3(0.0,0.0,-epsilon)));
}

void main()
{
	float fov = 70.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

	vec3 camP = vec3(0.0, 0.0, iGlobalTime);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));

	vec3 lightPos = vec3(1.0, 0.0, 0.0);

	float t = 10000.0;
	float newT = 10000.0;
	float glowT = 10000.0;

	vec4 sphereColor = vec4(0.5,1.0,1.0,1.0);

	vec3 newPos = camP;

	for(int i = 0; i <= maxIterations; i++)
	{
		newT = distance(newPos);
		if(newT < t) glowT = newT;
		t = newT;

		newPos = newPos + camDir*t;
		if(newT <= epsilon) 
		{
			vec3 normal = normalize(getNormal(newPos));
			//vec3 color = mix(vec3(0.5,1.0,1.0), vec3(1.0,0.5,1.0), length(camP+t*camDir)/10);
			//gl_FragColor = vec4(color,1.0);
			vec4 color = sphereColor*max(0.2, dot(normal, normalize(lightPos-newPos)));
			//gl_FragColor = color;

			gl_FragColor = mix(color*(glowEpsilon-glowT)*6, vec4(0.8,0.5,1.0,1.0), length(newPos-camP)/200);
			return;
		}
		//else gl_FragColor = mix(vec4(0.0,0.0,0.0,0.0)+vec4(1.0,1.0,0.5,1.0), vec4(1.0,0.5,1.0,1.0), length(newPos-camP)/100);

		//else if(glowT < glowEpsilon) gl_FragColor = vec4(0.0,0.0,0.0,0.0)+sphereColor*(glowEpsilon-glowT)*20;
		else if (glowT < glowEpsilon) gl_FragColor = mix(vec4(0.0,0.0,0.0,0.0)+sphereColor*(glowEpsilon-glowT)*12, vec4(0.8,0.5,1.0,1.0), length(newPos-camP)/100);
		//else gl_FragColor = mix(vec4(0.0,0.0,0.0,0.0), vec4(1.0,0.5,0.5,1.0),length(newPos-camP)/200);

		//else gl_FragColor = mix(vec4(0.0,0.0,0.0,0.0), vec4(0.9,0.4,0.9,0.9), length(newPos-camP)/400);

	}		
	

}


