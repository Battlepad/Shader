uniform vec3 iMouse;
uniform vec2 iResolution;
uniform float iGlobalTime;
varying vec2 uv;

float time=iGlobalTime;

const float epsilon = 0.001;
const int maxIterations = 128;
const float glowEpsilon = 0.1;



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
	float radius = 0.800;
	vec3 b = vec3(6.0,6.0,0.0);
	point = repeat(point, b);
	return distSphere(point, spherePos, radius);
}

Intersection rayMarch(vec3 origin, vec3 direction)
{
	Intersection intersect;

	vec3 lightPos = vec3(1.0, 0.0, 0.0);
	vec4 sphereColor = vec4(1.0,0.3,0.3,1.0);
	vec4 fogColor = vec4(0.5,0.5,1.0,1.0);
	
	float t = 10000.0;

	vec3 newPos = origin;

	for(int i = 0; i <= maxIterations; i++)
	{
		t = distance(newPos);
		newPos = newPos + direction*t;

		if(t < epsilon) 
		{
			intersect.exists = true;

			vec3 normal = getNormal(newPos);
			vec3 reflection = normalize(reflect(camDir, normal));
			vec3 newPosReflect = newPos + normal * 0.1;

			//Intersection intersect = rayMarch(newPos+normal*0.1, reflect(direction, getNormal(newPos)));

			vec4 color = sphereColor*max(0.2, dot(normal, normalize(lightPos-newPos)));
			intersect.color = mix(color, fogColor, length(newPos-origin)/100);

			return intersect;
		}
	}
}

vec3 getNormal(vec3 point)
{
	//grad of the vector (= normal)
	return normalize(vec3(distance(point + vec3(epsilon,0.0,0.0)) - distance(point + vec3(-epsilon,0.0,0.0)),
				distance(point + vec3(0.0,epsilon,0.0)) - distance(point + vec3(0.0,-epsilon,0.0)),
				distance(point + vec3(0.0,0.0,epsilon)) - distance(point + vec3(0.0,0.0,-epsilon))));
}

void main()
{
	float fov = 70.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

	vec3 camP = vec3(sin(iGlobalTime), 0.0, -20.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));

	gl_FragColor = vec4(0.0,0.0,0.0,0.0);

	Intersection intersect = rayMarch(camP, camDir);

	if(intersect.exists)
		gl_FragColor = intersect.color;



	gl_FragColor = mix(vec4(0.0,0.0,0.0,0.0),fogColor, length(newPos-camP)/200);

}		