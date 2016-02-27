uniform vec2 iResolution;
uniform float iGlobalTime;
uniform sampler2D tex;
uniform sampler2D tex1;

/************************************************************
*	Input Uniforms
*************************************************************/
//Position
uniform float cameraX = 10.0;
uniform float cameraY = 25.0;
uniform float cameraZ = 10.0;

//Roation
uniform float angleX = 90.0;
uniform float angleY = 90.0;
uniform float angleZ = 90.0;

uniform float interpolate = 0.0; 

in vec2 uv;
#define Pi 3.1415926535897932384626433832795


const float SIZE = 50.0;
const float HEIGHT = 2.0;
const float deltaEpsilon = 0.1;
const float maxIteration = 64.0;
const float minEpsiolon = 0.01;
const float glowEpsiolon = 0.1;
const float k = 32.0;
const float toRadian = Pi/180.0;
const float blurSize = 10.0;


float fov = 45.0;
// vec3 pointLight = vec3(sin(iGlobalTime),  cos(iGlobalTime), iGlobalTime);
vec3 pointLight = normalize(vec3(0,-0.5,1));



/************************************************************
*	Structs
*************************************************************/
struct Ray
{
	vec3 origin;
	vec3 direction;
};

struct Material
{
	sampler2D tex;
	float Shininess;
	float reflection;
	vec4 color;
	vec3 glow;

};

struct Intersection
{
	vec3 intersectP;
	Material mat;
	vec3 normal;
	bool exists;
};


/************************************************************
*	Function Definitions
*************************************************************/

Intersection RayMarching(Ray cam);
Ray Init();
vec3 CalcNormal(vec3 p);
vec3 Rotate(vec3 object, vec3 angles);
float Sphere(vec3 p, vec3 m, float r);
float sdTorus(vec3 p, vec2 t);
float opTiwst(vec3 p, vec3 mid, float r);
float DrawScene(vec3 p);
float Union(float object1, float object2);
float Difference(float object1, float object2);
float DistScene(vec3 p);
vec4 ApplyFog(vec4 originalColor, float fogAmount);
float GetHeight();
vec3 BiSection(Ray cam, float t);
float heightCalcing(vec3 p);
vec3 BiSection2(Ray cam, float t);
float CalcShadow(vec3 p, vec3 d);

/************************************************************
*	Objects
*************************************************************/
float Sphere(vec3 p, vec3 m, float r)
{
	return length(p-m) -r;
}

float sdTorus(vec3 p, vec2 t)
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float distPlane( vec3 p, vec4 n )
{
  // n must be normalized
  return dot(p,n.xyz) + n.w;
}



/***********************************************************
*	Inizialization
************************************************************/
Ray Init()
{
	float fov = 90.0;
	float tanFov = tan(fov / 2.0 * Pi / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

	Ray r1; 
	// r1.origin = vec3(sin(iGlobalTime)*10, 100.0 ,cos(iGlobalTime));
	r1.direction = Rotate(vec3(p.x, p.y, 1), vec3(90.0, angleY, angleZ));
	r1.origin = vec3(cameraX, cameraY, cameraZ);
	// r1.direction = normalize(vec3(p.x, p.y, 1.0));
	return r1;
}


/***********************************************************
*	Operations
************************************************************/
vec3 Rotate(vec3 object, vec3 angles)
{
	float anglex = angles.x * toRadian;
	float angley = angles.y * toRadian;
	float anglez = angles.z * toRadian;

	mat3 rx = mat3(1.0, 0.0, 		   0.0,
				   0.0, cos(anglex), -sin(anglex),
				   0.0, sin(anglex), cos(anglex));

	mat3 ry = mat3(cos(angley),  0.0, sin(angley),
				   0.0,			   1.0, 0.0,
				   -sin(angley), 0.0, cos(angley));

	mat3 rz = mat3(cos(anglez), -sin(anglez), 0.0,
				   sin(anglez), cos(anglez),  0.0,
				   0.0,			  0.0, 			  1.0);

	// mat3 rm = rx * ry * rz;
	return object * rx * ry * rz;
}




/***********************************************************
*	Helping Functions
************************************************************/
vec3 CalcNormal(vec3 p)
{
	float h = 0.1;
	return normalize(vec3( 
		heightCalcing(vec3(p.x-h,p.y, p.z)) - heightCalcing(vec3(p.x+h,p.y, p.z)),
        2.0*minEpsiolon,
        heightCalcing(vec3(p.x, p.y, p.z-h)) -  heightCalcing(vec3(p.x, p.y, p.z+h))));
}

vec3 Blur(vec3 p)
{	
	vec2 uv = p.xz /SIZE;
	// return mix(texture(tex, uv), texture(tex1, uv), iGlobalTime/500.0);
	vec3 blur1 = vec3(0);
	vec3 blur2 = vec3(0);
	for(float i = -blurSize; i < blurSize; ++i)
	{
		for(float j = -blurSize; j < blurSize; ++j)
		{
			// blur1 += texture(tex, uv+vec2(i, j));
			// blur2 += texture(tex1, uv+vec2(i, j));
			blur1 += texture(tex, (p.xz+vec2(i, j))/SIZE);
			blur2 += texture(tex1, (p.xz+vec2(i, j))/SIZE);
		}
	}
	blur1 /= 4.0 * blurSize * blurSize;
	blur2 /= 4.0 * blurSize * blurSize;
	return mix(blur1, blur2, iGlobalTime/500.0);

}

//used for HeightFields 
float heightCalcing(vec3 p)
{
	float height_1 = texture(tex, p.xz /SIZE).x * HEIGHT;
	float height_2 = texture(tex1, p.xz /SIZE).x * HEIGHT; 
	return mix(height_1, height_2, interpolate);
}


vec3 BiSection(vec3 origin, vec3 dir, float t)
{

	float minT = t - deltaEpsilon;
	float maxT = t;

	vec3 p = origin + minT * dir;

	for(float i = 1.0; i <15.0; ++i)
	{
		t = (minT + maxT) * 0.5;
		p = origin + t * dir;
		float height = heightCalcing(p);
		if(height > p.y)
		{
			maxT = t;
		}
		else if(height < p.y)
		{
			minT = t;
		} 
	}
	return p;
}


/***********************************************************
*	Lighting
************************************************************/
float CalcLighting(vec3 p)
{
	vec3 normal = CalcNormal(p);
	// gl_FragColor = vec4(normal,1);
	vec3 lightDirection = normalize(pointLight - p);
	//float shadow = CalcShadow(p, -lightDirection);
	return max(0.1, dot(lightDirection, normal));
}

/***********************************************************
*	Shadowing
************************************************************/
float CalcShadow(vec3 p, vec3 d)
{
	Ray r;
	r.origin = p;
	r.direction = d;
	if(RayMarching(r).exists)
	{
		return 0.1;
	}
	else
	{
		return 1.0;
	}
}


vec4 ApplyFog(vec4 originalColor, float fogAmount)
{
    vec4  fogColor  = vec4(0);
    return mix( originalColor, fogColor, fogAmount );
}


Intersection RayMarching(Ray cam)
{

	const float minT = 5.00;
	const float maxT = 26.0;
	vec4 color1 = vec4(0.0);
	vec4 color2 = vec4(0.0);
	float height = 0.0;
	float t = 0.0;
	vec3 p = cam.origin;
	
	Intersection intersect;
	intersect.exists = false;
	intersect.mat.glow = vec3(0.0);

	for(t = minT; t < maxT; t+=deltaEpsilon)
	{
		p = cam.origin + t * cam.direction;		
		height = heightCalcing(p);
		if(height > p.y)
		{
			intersect.exists = true;
			intersect.intersectP = BiSection(cam.origin, cam.direction, t);
			color1 = vec4(texture(tex, intersect.intersectP.xz/SIZE).rgb, 1.0);
			color2 = vec4(texture(tex1, intersect.intersectP.xz/SIZE).rgb, 1.0);
			intersect.mat.color = mix(color1, color2, interpolate);
			intersect.mat.color *= CalcLighting(intersect.intersectP);
			//intersect.mat.color = intersect.mat.color * vec4(0.6, 0.75, 0.55, 1.0);
			intersect.mat.color = ApplyFog(intersect.mat.color, min(0.1, t/100.0));

			if(height < 2.0)
			{
				intersect.mat.glow += intersect.mat.color * CalcLighting(p) ;
				vec3 normal = CalcNormal(intersect.intersectP);
				// float intensity = 1.0 - dot(normal, vec3(0.0, 1.0, 0.0));
				// intersect.mat.glow += vec3(1.0) * pow(intensity, 2);

				intersect.mat.color.rgb += Blur(intersect.intersectP) * 0.5;
				//intersect.mat.color = ApplyFog(vec4(0.7, 0.2, 0.6, 1.0), t/100.0);
			}
			return intersect;
		}
	}
	return intersect;
}

void main()
{
	Ray cam = Init();
	Intersection obj = RayMarching(cam);
	if(obj.exists)
	{
		obj.mat.color += vec4(obj.mat.glow, 1.0);
		gl_FragColor = obj.mat.color;
	}
	else
	{
		gl_FragColor = ApplyFog(vec4(0.0, 0.0, 0.0, 1.0), 0.1);
	}
}