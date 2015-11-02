#version 330
uniform vec3 iMouse;
uniform vec2 iResolution;
uniform float iGlobalTime;
varying vec2 uv;

const float bigNumber = 10000.0;
const float eps = 0.001;
vec3 toLight = normalize(vec3(sin(iGlobalTime + 2.0), 0.6, cos(iGlobalTime + 2.0)));
const float ambient = 0.2;

float quad(float a)
{
	return a * a;
}

vec3 background(vec3 dir)
{
	float sun = max(0.0, dot(dir, toLight));
	float sky = max(0.0, dot(dir, vec3(0.0, 1.0, 0.0)));
	float ground = max(0.0, -dot(dir, vec3(0.0, 1.0, 0.0)));
	return 
  (pow(sun, 256.0) + 0.2 * pow(sun, 2.0)) * vec3(2.0, 1.6, 1.0) +
  pow(ground, 0.5) * vec3(0.4, 0.3, 0.2) +
  pow(sky, 1.0) * vec3(0.5, 0.6, 0.7);
}

float sphere(vec3 M, float r, vec3 O, vec3 d)
{
	vec3 MO = O - M;
	float root = quad(dot(d, MO))- quad(length(d)) * (quad(length(MO)) - quad(r));
	if(root < eps)
	{
		return -bigNumber;
	}
	float p = -dot(d, MO);
	float q = sqrt(root);
    return (p - q) > 0.0 ? p - q : p + q;
}

//dot(n, O +t*d)= -k
//dot(n,O) + dot(n, t*d) = -k
//t*dot(n,d)=-k-dot(n,O)
float plane(vec3 n, float k, vec3 O, vec3 d)
{
	float denominator = dot(n, d);
	if(abs(denominator) < eps)
	{
		//no intersection
		return -bigNumber;
	}
	return (-k-dot(n,O)) / denominator;
}	

vec3 sphereNormal(vec3 M, vec3 P)
{
	return normalize(P - M);
}

vec3 sphereColor(vec3 M)
{
	return abs(normalize(M - vec3(0.0, 0.0, 1.2)));
}

float calcLighting(vec3 n)
{
	return max(ambient, dot(n, toLight));
}

struct Intersection
{
	bool exists;
	vec3 n;
	vec3 color;
	vec3 intersectP;
};
Intersection rayCastScene(vec3 O, vec3 d)
{
	float t = bigNumber;
	vec3 M = vec3(-bigNumber);
	vec3 normal = vec3(0.0, 0.0, 0.0);
	for(float x = -2.0; x <= 2.0; x += 0.7)
	{
		float y = -1.0;
		for(float z = 1.0; z <= 10.0; z += 0.7)
		{	
			vec3 newM = vec3(x, y, z);
			float newT = sphere(newM, 0.1, O, d);
			if (0.0 < newT && newT < t)
			{	
				t = newT;
				M = newM;
			}
		}
	}
	Intersection obj;
	obj.n = normalize(vec3(0.0, 1.0, 0.1));
	float newT = plane(obj.n, 0.9, O, d);
	if (0.0 < newT && newT < t)
	{
		obj.exists = true;
		obj.color = vec3(0.5, 0.5, 0.5);
		obj.intersectP = O + newT * d;
		return obj;
	}
	obj.exists = t < bigNumber;
	if(!obj.exists) return obj;
	obj.color = sphereColor(M);
	obj.intersectP = O + t * d;
	obj.n = sphereNormal(M, obj.intersectP);
	return obj;
}

void main()
{
	//camera
	float fov = 60.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);
	vec3 camP = vec3(0.0, 0.0, -1.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));
	
	vec3 color = background(camDir);
	//primary ray
	Intersection obj = rayCastScene(camP, camDir);
	if(obj.exists) 
	{
		color = obj.color;
		//numerical stable point
		obj.intersectP += obj.n * eps;
		//shadow ray
		if(rayCastScene(obj.intersectP, toLight).exists)
		{
			color *= ambient;
		}
		else
		{
			color *= calcLighting(obj.n);
		}
	
		//secondary ray - reflexion
		vec3 r = reflect(camDir, obj.n);
		obj = rayCastScene(obj.intersectP, r);
		if(obj.exists) 
		{
			color += obj.color
			* calcLighting(obj.n)
			* 0.9;
		}
		else
		{
			color += background(r) * 0.6;
		}
	}

	gl_FragColor = vec4(color, 1.0);
}