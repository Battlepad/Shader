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
	float t;
	bool exists;
};

float distFunc(vec3 p)
{
    return length(mod(p+vec3(0,0,mod(-time*19.,4.)),4.)-2.)-.4;
}

float quad(float a)
{
	return a * a;
}

float sphere(vec3 M, vec3 O, vec3 d, float _r)
{
	float r = _r;
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

//dot(n, O +t*d)= -k
//dot(n,O) + dot(n, t*d) = -k
//t*dot(n,d)=-k-dot(n,O)
float plane(vec3 n, float k, vec3 O, vec3 d)
{
	float denominator = dot(n, d);
	if(abs(denominator) < 0.001)
	{
		//no intersection
		return -10000.0;
	}
	return (-k-dot(n,O)) / denominator;
}

Intersect RenderScene(vec3 orig, vec3 direction)
{
	Intersect intersection;
	intersection.exists = false;

	intersection.t = 10000.0;

	//float y = 0.0;
	//float z = 0.0;
	
	// for(float x = -0.45; x <= 0.5; x += 0.3)
	// {
	// 	//vec3 spherePos = vec3(x, y*sin(iGlobalTime+x)/4, z*cos(iGlobalTime+x)/4);
	// 	vec3 spherePos = vec3(x, y, z);

	// 	float newT = sphere(spherePos, orig, direction);
	// 		if (0.0 < newT && newT < intersection.t)
	// 		{	
	// 			intersection.t = newT;
	// 			intersection.M = spherePos;
	// 			intersection.color = vec3(x,1.0,1.0);
	// 			intersection.exists = true;
	// 		}
	// 	//y += 0.2;
	// }
	float x = 0.0;
	float y = 0.0;
	float radius = 0.1;
	float newT = 0.0;
	for(float z = -0.45; z <= 2.5; z += 0.5)
	{
		//vec3 spherePos = vec3(x, y*sin(iGlobalTime+x)/4, z*cos(iGlobalTime+x)/4);
		vec3 spherePos = vec3(z, y, x);

		newT = sphere(spherePos, orig, direction, radius);
			if (0.0 < newT && newT < intersection.t)
			{	
				intersection.t = newT;
				intersection.normal = normalize(orig + intersection.t*direction - spherePos);
				intersection.color = vec3(x,1.0,1.0);
				intersection.exists = true;
			}
			radius += 0.05;
		//y += 0.2;
	}

	vec3 normal = vec3(0.0, 1.0, 0.1);
	newT = plane(normal, 0.9, orig, direction);
	if(newT > 0.0 && newT < intersection.t)
	{
		intersection.t = newT;
		intersection.color = vec3(0.4,1.0,1.0);
		intersection.intersectP = orig + intersection.t*direction;
		intersection.normal = normal;
		intersection.exists = true;
	}

	vec3(-2.0*sin(iGlobalTime), 5.0, 0.0);

	return intersection;
}

Intersect ReflectRay(vec3 _intersectP, vec3 _direction, vec3 _normal)
{
	vec3 reflectedRay = normalize(reflect(_direction, _normal));
	Intersect intersection = RenderScene(_intersectP+_normal*0.0001, reflectedRay);
	return intersection;
}

Intersect CalcShadows(vec3 _intersectP, vec3 _lightPos, vec3 _normal)
{
	Intersect intersection;
	intersection = RenderScene(_intersectP+_normal*0.0001, normalize(_lightPos-_intersectP));
	return intersection;
}

// Intersect RenderLight()
// {
// 	Intersect intersection;
// 	intersection.exists = false;

// 	intersection.t = 10000.0;

// 	float x = 0.0;
// 	float y = 0.0;
// 	for(float z = -0.45; z <= 2.5; z += 0.3)
// 	{
// 		//vec3 spherePos = vec3(x, y*sin(iGlobalTime+x)/4, z*cos(iGlobalTime+x)/4);
// 		vec3 spherePos = vec3(z, y, x);

// 		float newT = sphere(spherePos, orig, direction);
// 			if (0.0 < newT && newT < intersection.t)
// 			{	
// 				intersection.t = newT;
// 				intersection.M = spherePos;
// 				intersection.color = vec3(x,1.0,1.0);
// 				intersection.exists = true;
// 			}
// 		//y += 0.2;
// 	}
// 	return intersection;
// }

void main()
{
	
	//float a = t < 10000.0 ? 1.0 : 0.0;
	//a *= 1.0 - t * 0.1;
	gl_FragColor = vec4(1.0,1.0,1.0,1.0);

	float fov = 90.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

	vec3 lightPos = vec3(-2.0*sin(iGlobalTime), 1.0, 0.0);
	vec3 camP = vec3(0.0, 0.5, -3.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));

	//RenderLight()

	Intersect intersection = RenderScene(camP, camDir);
	intersection.intersectP = camP + intersection.t*camDir;
	if (!intersection.exists)
	{
		gl_FragColor = vec4(1.0,1.0,1.0,1.0);
		return;
	}
	
	//Shadow Rays
	Intersect shadowIntersect = CalcShadows(intersection.intersectP, lightPos, intersection.normal);

	if(shadowIntersect.exists)
	{
		gl_FragColor = vec4(0.0,0.0,0.0,1.0);
	}
	else
	{
		//Point Light (Lambert?)
		vec3 reflectedColor = vec3(0.0,0.0,0.0);

		float pointLighting = dot(intersection.normal, normalize(lightPos - intersection.intersectP));
		vec3 colorPointLighting = intersection.color;

		//Specular Reflection
		float specularReflection = dot(normalize(reflect(lightPos - intersection.intersectP, intersection.normal)), //reflection between Lightray and Normal of Sphere
		 	normalize(camP-intersection.intersectP)); 
		specularReflection = pow(specularReflection,32);

		//Reflected Ray
		Intersect reflectedIntersect = ReflectRay(intersection.intersectP, camDir, intersection.normal);//RayReflection();
		if (reflectedIntersect.exists) reflectedColor = reflectedIntersect.color;

		vec3 color = abs(colorPointLighting+reflectedColor+specularReflection);
		color *= max(0.2, pointLighting);//+specularReflection*/);
		gl_FragColor = vec4(color, 1.0);
	}


	//Color calculation


	
	//gl_FragColor = vec4(a, a, a, 1.0);
}


