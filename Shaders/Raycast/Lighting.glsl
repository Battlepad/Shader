uniform vec3 iMouse;
uniform vec2 iResolution;
uniform float iGlobalTime;
varying vec2 uv;

float time=iGlobalTime;

struct Intersect
{
	vec3 intersectP;
	vec4 color;
	vec3 normal;
};

float distFunc(vec3 p)
{
    return length(mod(p+vec3(0,0,mod(-time*19.,4.)),4.)-2.)-.4;
}

float quad(float a)
{
	return a * a;
}

float sphere(vec3 M, vec3 O, vec3 d)
{
	float r = 0.1;
	vec3 MO = O - M;
	float root = quad(dot(d, MO))- quad(length(d)) * (quad(length(MO)) - quad(r));
	if(root < 0.001)
	{
		return -1000.0;
	}
	float p = -dot(d, MO);
	float q = sqrt(root);
    return (p - q) > 0.0 ? p - q : p + q;
}

void main()
{
	float fov = 90.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

	vec3 camP = vec3(0.0, 0.0, 0.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));

	vec3 lightPos = vec3(10.0, +20.0, 20.0);

	float t = 10000.0;
	vec3 M = vec3(1000.0,1000.0,1000.0);
	for(float x = -2.0; x <= 2.0; ++x)
	{
		for(float y = 1.0; y <= 2.0; ++y)
		{
			for(float z = 1.0; z <= 3.0; ++z)
			{	
				float newT = sphere(vec3(x, y*sin(iGlobalTime/2), z), camP, camDir);
				if (0.0 < newT && newT < t)
				{	
					t = newT;
					M = vec3(x,y,z);
				}
			}
		}
	}
	float a = t < 10000.0 ? 1.0 : 0.0;
	a *= 1.0 - t * 0.1;
	Intersect intersection;
	intersection.intersectP = camP + t*camDir;
	//intersection.normal = normalize(M + t*(intersection.intersectP - M));
	intersection.normal = normalize(intersection.intersectP - M);

	vec3 color = abs(normalize(vec3(M.x,M.y,M.z) - vec3(0.0, 1.5, 1.8)));
	color *= max(0.2, dot(intersection.normal, normalize(lightPos - intersection.intersectP)));

	gl_FragColor = vec4(color, 1.0);
	//gl_FragColor = vec4(a, a, a, 1.0);
}


