uniform vec3 iMouse;
uniform vec2 iResolution;
uniform float iGlobalTime;
varying vec2 uv;

vec3 dirLightPos;
vec4 globalObjectColor = vec4(0.0,0.0,0.0,1.0);
vec4 torusColor = vec4(1.0, 0.2, 0.0, 1.0);
vec4 sphereColor = vec4(1.0, 0.2, 0.0, 1.0);
vec4 planeColor = vec4(0.5, 1.0, 0.0, 1.0);

const float epsilon = 0.001;
const int maxIterations = 256;
const float shadowK = 24.0;

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
                0.0,                                0.0,                                0.0,                                1.0);
}

vec3 background(vec3 dir, vec3 _lightPos)
{
	float sun = max(0.0, dot(dir, _lightPos));
	return (sun*0.2* vec3(1.0, 1.0, 1.0));
}

float sphSoftShadow( in vec3 ro, in vec3 rd, in vec4 sph, in float k )
{
    vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - sph.w*sph.w;
    float h = b*b - c;
    
    float d = -sph.w + sqrt( max(0.0,sph.w*sph.w-h));
    float t = -b     - sqrt( max(0.0,h) );
    return (t<0.0) ? 1.0 : smoothstep( 0.0, 1.0, k*d/t );
}

// float softshadow( in vec3 origin, in vec3 dir, float mint, float maxt, float k )
// {
//     float res = 1.0;
//     for( float t = mint; t < maxt; )
//     {
//         float h = distScene(origin + dir * t);
//         if( h < epsilon )
//             return 0.0;
//         res = min( res, k*h/t );
//         t += h;
//     }
//     return res;
// }

vec3 repeat(vec3 P, vec3 b) //P ist Punkt wo man mit Marching gerade ist
{
	return mod(P,b)-b/2;
}

float distPlane( vec3 p, vec4 n )
{
  // n must be normalized
  return dot(p,n.xyz) + n.w;
}

float distSphere(vec3 p, vec3 m, float r){
	return length(p - m) - r;
}

float distTorus( vec3 p, vec3 m, vec2 t )
{
  vec2 q = vec2(length(p.xz-m.xz)-t.x,p.y-m.y);
  return length(q)-t.y;
}

vec3 opTx( vec3 p, mat4 m )
{
    vec3 q = inverse(m)*vec4(p,1.0);
    return q;
}

float distSphere(vec3 point){
	vec3 spherePos = vec3(0.0,0.0,0.0);
	float radius = 0.500;
	vec3 b = vec3(4.0,3.0,3.0);
	float dist = distSphere(point, spherePos, radius);
	return dist;
}

float opTwist( vec3 p )
{
    float c = cos(20.0*p.y);
    float s = sin(20.0*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xz,p.y);
    return distSphere(q, vec3(0.0,0.3,0.0), 0.500);
}

float distScene(vec3 point)
{
	float distance;
	//float distanceSphere = distSphere(point, vec3(0.0, sin(iGlobalTime)+1,0.0), 0.500);
	//float distanceSphere = opTwist(point);
	//float distanceTorus = distTorus(point, vec3(0.0, sin(iGlobalTime)/2,0.0), vec2(0.40,0.1));
	// float distanceTorus = distTorus(opTx(point, mat4(
 //                1, 0, 0, 0,
 //                0, cos(iGlobalTime), -sin(iGlobalTime), 0,
 //                0, sin(iGlobalTime), cos(iGlobalTime), 0,
 //                0.0, 0.0, 0.0, 1 )),vec3(0.0, 0.0,0.0), vec2(0.40,0.2)); //point to rotate around       
	
	float distanceSphere = distSphere(point, vec3(0), 0.1);
	float distanceTorus = distTorus(opTx(point, rotationMatrix(vec3(1.0,1.0,0.0), iGlobalTime)),vec3(0.0, 0.0,0.0), vec2(0.40,0.2)); //point to rotate around       


					//*mat4(
                //cos(iGlobalTime), 0, -sin(iGlobalTime), 0,
                //0, 1, 0, 0,
                //sin(iGlobalTime), 0, cos(iGlobalTime), 0,
                //0.0, 0.0, 0.0, 1 )


	//float distanceSphere2 = distSphere(point, vec3(2.0, cos(iGlobalTime)+1,0.0), 0.500);
	float distancePlane = distPlane(point, vec4(0.0,1.0,0.0,1.0));

	float distanceTmp = min(distanceTorus, distanceSphere);
	distanceTmp = min(distanceTorus, distanceSphere);
	globalObjectColor = distanceTorus == distanceTmp ? torusColor : sphereColor;
	distanceTmp = min(distancePlane, distanceTmp);
	globalObjectColor = distancePlane == distanceTmp ? planeColor : globalObjectColor;


	//distance = min(distanceSphere, distanceSphere2);
	//distance = min(distance, distancePlane);
	//return distance;
	distanceTmp = min(distanceTorus, distanceSphere);
	return distanceTmp;
}

vec3 getNormal(vec3 point)
{
	//grad of the vector (= normal)
	float d = epsilon;
	vec3 left = point + vec3(-d, 0.0, 0.0);
	vec3 right = point + vec3(d, 0.0, 0.0);
	vec3 up = point + vec3(0.0, d, 0.0);
	vec3 down = point + vec3(0.0, -d, 0.0);
	vec3 behind = point + vec3(0.0, 0.0, d);
	vec3 before = point + vec3(0.0, 0.0, -d);

	//gradient
	vec3 gradient = vec3(distScene(right) - distScene(left),
						distScene(up) - distScene(down),
						distScene(behind) - distScene(before));
	return normalize(gradient);
}

float softShadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k )
{
    float res = 1.0;
    for( float t=mint; t < maxt; )
    {
        float h = distScene(ro + rd*t);
        if( h<0.001 )
            return 0.0;
        res = min( res, k*h/t );
        t += h;
    }
    return res;
}

Intersection rayMarch(vec3 origin, vec3 direction)
{
	Intersection intersect;
	intersect.exists = false;

	vec4 sphereColor = vec4(1.0, 0.2, 0.0, 1.0);
	
	float tSphere = 10000.0;
	float tPlane = 10000.0;

	vec3 newPos = origin;

	for(int i = 0; i <= maxIterations; i++)
	{
		float t = distScene(newPos);
		//tSphere = distance(newPos);
		//tPlane = sdPlane(newPos, vec4(0.0,1.0,0.0,1.0));
		newPos += direction*t;

		if(t < epsilon) 
		{
			intersect.exists = true;
			intersect.normal = getNormal(newPos);

			vec4 color = globalObjectColor;
			intersect.color = color;
			
			intersect.intersectP = newPos;

			return intersect;
		}
	}
	intersect.intersectP = newPos;
	intersect.color = vec4(0.0,0.0,0.0,0.0);
	return intersect;
}

void main()
{
	float fov = 70.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

	vec3 camP = vec3(0.0, 0.0, -5.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));

	vec3 areaLightPos = vec3(0.5, 3.0, -1.0);
	dirLightPos = opTx(vec3(4.0,2.0,0.0),rotationMatrix(vec3(0.0,1.0,0.0), iGlobalTime));
	vec3 lightDirection = normalize(vec3(-1.0,-1.0,0.0));

	vec4 fogColor = vec4(0.0,0.7,0.7,1.0);
	vec3 bgColor = background(camDir, dirLightPos);
	float fog = 200.0;

	Intersection intersect = rayMarch(camP, camDir);

	if(intersect.exists)
	{
		vec3 lightDir = normalize(dirLightPos - intersect.intersectP);
		float shadow = max(0.2, softShadow(intersect.intersectP, lightDir, 0.1, length(dirLightPos - intersect.intersectP), shadowK));
		intersect.color = intersect.color*shadow;

		Intersection reflIntersect = rayMarch(intersect.intersectP+intersect.normal*0.01, normalize(reflect(camDir, intersect.normal)));
		if(reflIntersect.exists)
		{
			float shadowReflect = max(0.2, softShadow(reflIntersect.intersectP, lightDir, 0.1, length(dirLightPos - reflIntersect.intersectP), shadowK));
			reflIntersect.color = reflIntersect.color*shadowReflect;
		}

		//Soft Shadows
		gl_FragColor = mix(intersect.color+reflIntersect.color, fogColor, length(intersect.intersectP-camP)/fog);
	}		
	else
		gl_FragColor = mix(vec4(bgColor,1.0),fogColor, 0.65);
		//gl_FragColor = vec4(bgColor,1.0);
}		