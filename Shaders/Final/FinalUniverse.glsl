uniform vec2 iResolution;
uniform float iGlobalTime;

uniform float time;

uniform float toPrism;
uniform float toCylinder;
uniform float toTorus;
uniform float toSphere;

uniform float planetSize;
uniform float planetPosX;

uniform float boxColorInterpolate;
uniform float boxColorEndInterpolate;

const float epsilon = 0.001;
const int maxIterations = 128;
const vec3 boxPos = vec3(0.0,0.0,5.5);

vec4 globalColor = vec4(0.0);
vec4 boxColor = vec4(0.15,0.87,0.77,1.0);
vec4 planetColor = vec4(1.0,0.42,0.36,0.0);

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

mat4 translationMatrix(vec3 delta)
{
    return mat4(    1.0,    0.0,    0.0,    delta.x,
                    0.0,    1.0,    0.0,    delta.y,
                    0.0,    0.0,    1.0,    delta.z,
                    0.0,    0.0,    0.0,    1.0     );
}

mat4 lookAt(vec3 eye, vec3 center, vec3 up)
{
    vec3 zaxis = normalize(center - eye);
    vec3 xaxis = normalize(cross(up, zaxis));
    vec3 yaxis = cross(zaxis, xaxis);

    mat4 matrix;
    //Column Major
    matrix[0][0] = xaxis.x;
    matrix[1][0] = yaxis.x;
    matrix[2][0] = zaxis.x;
    matrix[3][0] = 0;

    matrix[0][1] = xaxis.y;
    matrix[1][1] = yaxis.y;
    matrix[2][1] = zaxis.y;
    matrix[3][1] = 0;

    matrix[0][2] = xaxis.z;
    matrix[1][2] = yaxis.z;
    matrix[2][2] = zaxis.z;
    matrix[3][2] = 0;

    matrix[0][3] = -dot(xaxis, eye);
    matrix[1][3] = -dot(yaxis, eye);
    matrix[2][3] = -dot(zaxis, eye);
    matrix[3][3] = 1;

    return matrix;
}

float opS( float d1, float d2 )
{
    return max(-d1,d2);
}

float distBox(vec3 p, vec3 data )
{
    return max(max(abs(p.x)-data.x,abs(p.y)-data.y),abs(p.z)-data.z);
}

float distTriPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
    return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
}

float distCylinder( vec3 p, vec2 h )
{
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float distTorus( vec3 p, vec2 t )
{
    vec2 q = vec2(length(p.xz)-t.x,p.y);
    return length(q)-t.y;
}

float distSphere(vec3 p, float r)
{
    return length(p) - r;
}

float distPlanet(vec3 p, vec3 sphPos, vec3 plPos)
{
    return opS(distSphere(vec4(p.xyz,1.0)
        *translationMatrix(sphPos), 0.25/(7.0/planetSize)),distSphere(vec4(p.xyz,1.0)
        *translationMatrix(plPos), planetSize));
}

float distForms(vec3 p)
{
    float box = distBox(p, vec3(0.5));
    float triPrism = distTriPrism(p, vec2(0.5));
    float cylinder = distCylinder(p, vec2(0.5));
    float torus = distTorus(p, vec2(0.5));
    float sphere = distSphere(p, 0.5);
    return mix(mix(mix(mix(box, triPrism, toPrism), cylinder, toCylinder), torus, toTorus), sphere, toSphere);

}

vec3 repeat(vec3 P, vec3 b)
{
    return mod(P,b)-b/2;
}

vec3 repeat2(vec3 P, vec3 b)
{
    return mod(P-vec3(3.0,7.0,0.0), b)-b/2;
}

float distSceneReflection(vec3 point)
{
    vec3 b1 = vec3(5.0,3.0,5.0);
    vec3 b2 = vec3(4.5,7.3,4.2);

    float d1 = distBox(repeat((vec4(point.xyz,1.0)*translationMatrix(vec3(0.0,0.0,0.0-time))).xyz, b1),
        vec3(0.1,0.1,0.1));
    float d2 = distBox(repeat2((vec4(point.xyz,1.0)*translationMatrix(vec3(-time,time,0.0))).xyz, b2),
        vec3(0.1,0.1,0.1));
    return min(d1,d2);
}

float distScene(vec3 point)
{
    float planetPosZ = 20.0;
    vec3 planetPos = vec3(planetPosX,0.0,20.0);

    float distanceForms = distForms(((vec4(point.xyz,1.0)
            *translationMatrix(boxPos) //translation of cube
            *rotationMatrix(vec3(0.5,0.7,0.4), iGlobalTime)) //rotation
            *translationMatrix(vec3(0.0,0.0,0.0))).xyz //translation
            ); 
    float distancePlanet = distPlanet(point, vec3(planetPosX+planetSize-0.98,0.0,planetPosZ+3.76/(12.0/planetPosX)), planetPos);
    globalColor = distanceForms < distancePlanet ? boxColor : planetColor;
    return min(distanceForms,distancePlanet);
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

Intersection rayMarch(vec3 origin, vec3 direction)
{
    Intersection intersect;
    intersect.exists = false;

    vec3 newPos = origin;
    newPos += 1.0*direction;

    float t = 1000.0;

    for(int i = 0; i <= maxIterations; i++)
    {
        t = distScene(newPos);

        if(t < epsilon)
        {
            intersect.exists = true;
            intersect.normal = getNormal(newPos);

            intersect.color = globalColor;
            
            intersect.intersectP = newPos;

            return intersect;
        }
        else
        {
            newPos += t*direction;
        }
    }
    intersect.intersectP = newPos;
    intersect.color = vec4(0.0,0.0,0.0,0.0);
    return intersect;
}

Intersection rayMarchReflect(vec3 origin, vec3 direction)
{
    Intersection intersect;
    intersect.exists = false;

    vec3 newPos = origin;
    newPos += 1.0*direction;

    float t = 1000.0;

    for(int i = 0; i <= maxIterations; i++)
    {
        t = distSceneReflection(newPos);

        if(t < epsilon)
        {
            intersect.exists = true;
            intersect.normal = getNormal(newPos);

            intersect.color = vec4(1.0,1.0,1.0,1.0);
            
            intersect.intersectP = newPos;

            return intersect;
        }
        else
        {
            newPos += t*direction;
        }
    }
    intersect.intersectP = newPos;
    intersect.color = vec4(0.0,0.0,0.0,0.0);
    return intersect;
}

void main()
{
    float fov = 90.0;
    float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
    vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

    vec3 camP = vec4(0, 0, 5.0,1.0);
    vec3 camDir = normalize(vec3(p.x, p.y, -1.0));

    vec3 areaLightPos = vec3(0.0,-10.0,10.0);

    Intersection intersect = rayMarch(camP, camDir);

    if(intersect.exists)
    {
        float lighting = max(0.2, dot(intersect.normal, normalize(areaLightPos-intersect.intersectP)));
        Intersection reflectionStarsIntersect = rayMarchReflect(intersect.intersectP+intersect.normal*0.01, normalize(reflect(camDir, intersect.normal)));
        Intersection reflectionSpheresIntersect = rayMarch(intersect.intersectP+intersect.normal*0.01, normalize(reflect(camDir, intersect.normal)));

        if(distance(reflectionStarsIntersect.intersectP, intersect.intersectP) > 25 && distance(reflectionStarsIntersect.intersectP, intersect.intersectP) < 75)
        {
            gl_FragColor = mix((intersect.color+reflectionStarsIntersect.color)*lighting*1.2, vec4(0.0), boxColorEndInterpolate);
        }
        else
        {
            gl_FragColor = mix(intersect.color*lighting, vec4(0.0), boxColorEndInterpolate);
        }
        if(reflectionSpheresIntersect.exists)
        {
            gl_FragColor = gl_FragColor+reflectionSpheresIntersect.color*0.7;
        }
    }   
    else
    {
        vec2 position = ( gl_FragCoord.xy - iResolution.xy*.5 ) / iResolution.x;

        float angle = atan(position.y,position.x)/(2.*3.14159265359);
        angle -= floor(angle);
        float rad = length(position);
        
        float color = 0.0;
        for (int i = 0; i < 5; i++) 
        {
            float angleFract = fract(angle*36.);
            float angleRnd = floor(angle*360.)+1.;
            float angleRnd1 = fract(angleRnd*fract(angleRnd*.7235)*45.1);
            float angleRnd2 = fract(angleRnd*fract(angleRnd*.82657)*13.724);
            float t = time*5.0+angleRnd1*100.;
            float radDist = sqrt(angleRnd2+float(i));
            
            float adist = radDist/rad*.1;
            float dist = (t*.2+adist);
            dist = abs(fract(dist)-.5);
            color += max(0.,.5-dist*100./adist)*(.5-abs(angleFract-.5))*5./adist/radDist;
            
            angle = fract(angle);
        }    
        gl_FragColor = mix(vec4(color,color,color,1.0), vec4(0.0), boxColorInterpolate);
    }
}