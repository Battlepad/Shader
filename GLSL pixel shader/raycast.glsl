uniform vec2 iResolution;
uniform float iGlobalTime;

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

	float t = 10000.0;
	for(float x = -2.0; x <= 2.0; ++x)
	{
		for(float y = -2.0; y <= 2.0; ++y)
		{
			for(float z = 1.0; z <= 5.0; ++z)
			{	
				float newT = sphere(vec3(x, y, z), camP, camDir);
				if (0.0 < newT && newT < t)
				{	
					t = newT;
				}
			}
		}
	}
	float a = t < 10000.0 ? 1.0 : 0.0;
	a *= 1.0 - t * 0.1;
	gl_FragColor = vec4(a, a, a, 1.0);
}


