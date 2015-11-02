uniform vec3 iMouse;
uniform vec2 iResolution;
uniform float iGlobalTime;
varying vec2 uv;

float time=iGlobalTime;

struct Intersect
{
	vec3 intersectP;
	vec3 color;
	vec3 normal;
	vec3 M;
	float t;
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

Intersect RenderScene(vec3 orig, vec3 direction)
{
	vec3 M = vec3(1000.0,1000.0,1000.0);
	Intersect intersection;

	intersection.t = 10000.0;

	float y = 1.0;
	float z = -10.0;
	
	for(float x = -1.4; x <= 0.0; x += 0.3)
	{
		//vec3 spherePos = vec3(x, y*sin(iGlobalTime+x)/4, z*cos(iGlobalTime+x)/4);
		vec3 spherePos = vec3(x, y*sin(iGlobalTime)/8, z);

		float newT = sphere(spherePos, orig, direction);
			if (0.0 < newT && newT < intersection.t)
			{	
				intersection.t = newT;
				intersection.M = spherePos;
				intersection.color = vec3(x+y,y*0.1,0.6);
			}
		y += 0.2;
	}
	return intersection;
}

Intersect ReflectRay(vec3 orig, vec3 dest, vec3 normal)
{
	vec3 reflectedRay = normalize(reflect(normalize(dest-orig), normal));
	Intersect intersection = RenderScene(dest+normal*0.01, reflectedRay);
	return intersection;
}

void main()
{
	
	//float a = t < 10000.0 ? 1.0 : 0.0;
	//a *= 1.0 - t * 0.1;
	gl_FragColor = vec4(1.0,1.0,1.0,1.0);

	float fov = 90.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

	vec3 lightPos = vec3(0.0, 10.0, -10.0);
	vec3 camP = vec3(-1.0, 0.0, -11.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));

	Intersect intersection = RenderScene(camP, camDir);
	intersection.intersectP = camP + intersection.t*camDir;
	intersection.normal = normalize(intersection.intersectP - intersection.M);
	
	//Point Light (Lambert?)
	float pointLighting = dot(intersection.normal, normalize(lightPos - intersection.intersectP));
	vec3 colorPointLighting = intersection.color;

	//Specular Reflection
	float specularReflection = dot(normalize(reflect(lightPos - intersection.intersectP, intersection.normal)), //reflection between Lightray and Normal of Sphere
	 	normalize(camP-intersection.intersectP)); 
	specularReflection = pow(specularReflection,8);

	//Reflected Ray
	Intersect reflectedIntersect = ReflectRay(camP, intersection.intersectP, intersection.normal);//RayReflection();
	vec3 reflectedColor = reflectedIntersect.color;

	//

	//Color calculation
	vec3 color = abs(colorPointLighting+reflectedColor+specularReflection);
	color *= max(0.2, pointLighting);//+specularReflection*/);

	gl_FragColor = intersection.t == 10000.0 ? vec4(1.0,1.0,1.0,1.0) : vec4(color, 1.0);
	//gl_FragColor = vec4(a, a, a, 1.0);
}


