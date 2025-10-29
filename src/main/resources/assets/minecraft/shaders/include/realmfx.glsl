
float tlinear(float t) {
    return max(1.0-t, 0.0);
}
float teasedFx(float t_linear) {
    const float a = 2.262857;
    const float b = -1.69714;
    const float c = 0.43428;
    return 1. - (a * pow(t_linear, 3.0) + b * pow(t_linear, 2.0) + c * t_linear);
}

float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

float sdRing(vec2 p, float r1, float r2) {
    return max(sdCircle(p, r2), -sdCircle(p, r1));
}

float starSDF(vec2 p, int points, float innerR, float outerR, float rotation) {
    float n = float(points);
    float an = PI / n;
    float angle_p = atan(p.y, p.x) + rotation;
    float a = mod(angle_p, 2.0*an) - an;

    vec2 pl = vec2(cos(a), sin(a)) * length(p);
    pl.y = abs(pl.y);

    vec2 edge = vec2(cos(an), sin(an)) * outerR - vec2(innerR, 0.0);
    vec2 rel = pl - vec2(innerR, 0.0);
    float t = clamp(dot(rel, edge) / dot(edge, edge), 0.0, 1.0);
    float d = length(rel - t * edge);

    return d * sign(rel.x * edge.y - rel.y * edge.x);
}

float crescentSDF(vec2 p, float r1, float r2, float offset) {
    return max(length(p) - r1, -(length(p - vec2(offset, 0.0)) - r2));
}

float sdCapsuleWiggly(vec2 p, vec2 a, vec2 b, float r, float iTime){
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba)/dot(ba, ba), 0.0, 1.0);
    float dist = length(pa - ba*h) - r;

    dist += 0.01*sin(30.0*(pa.x + iTime/10.0)) * cos(20.0*(pa.y - iTime/10.0));
    return dist;
}

float sdCircleWiggly(vec2 p, vec2 c, float r, float iTime){
    float dist = length(p - c) - r;
    dist += 0.01*sin(40.0*(p.x + iTime/10.0)) * cos(30.0*(p.y - iTime/10.0));
    return dist;
}

vec4 realmfx_star(float iTime, vec2 uv) {
    uv = gl_FragCoord.xy / ScreenSize.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= ScreenSize.x / ScreenSize.y;

    float t_linear = tlinear(iTime);
    float t_eased = teasedFx(t_linear);

    float minScale = 0.0001;
    float maxScale = 60.0;

    float scales = mix(maxScale, minScale, t_eased);
    uv /= scales;

    float innerRingOuterR = 0.2;
    float innerRingInnerR = 0.1;
    float spikeOuterR = 0.7;

    float r = PI*0.25;
    float d_spikes = starSDF(uv, 4, 0.1, 0.45, r);
    float d_spikesOuter = starSDF(uv, 4, 0.09, 0.22, PI*0.25+r);
    float d_spikeFill = starSDF(uv, 4, 0.06, 0.15, PI*0.25+r);
    float d_spikesCut = starSDF(uv, 4, 0.06, 0.2, r);

    float d = min(d_spikes, d_spikesOuter);
    d = max(d, -d_spikesCut); // sub
    d = min(d, d_spikeFill); // union

    float mask = step(0.0, -d);
    return vec4(vec3(0.0), 1.0-mask);
}

vec4 realmfx_sun(float iTime, vec2 uv) {
    uv = gl_FragCoord.xy / ScreenSize.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= ScreenSize.x / ScreenSize.y;

    float t_linear = tlinear(iTime);
    float t_eased = teasedFx(t_linear);

    float minScale = 0.0001;
    float maxScale = 60.0;

    float scales = mix(maxScale, minScale, t_eased);
    uv /= scales;

    float innerRingOuterR = 0.2;
    float innerRingInnerR = 0.1;
    float spikeOuterR = 0.7;

    float d_spikes = starSDF(uv, 4, 0.1, 0.55, 0.0);
    float d_spikesCut = starSDF(uv, 4, 0.05, 0.17, 0.0);

    float d_spikesOuter = starSDF(uv, 4, 0.09, 0.25, PI*0.25);

    float d_ring = sdRing(uv, innerRingInnerR, innerRingOuterR);

    float d_hole = sdCircle(uv, 0.11);
    float d_holeFill = sdCircle(uv, 0.07);

    float d = min(d_spikes, d_ring);
    d = min(d, d_spikesOuter); // union
    d = max(d, -d_hole); // subtract
    d = max(d, -d_spikesCut); // subtract
    d = min(d, d_holeFill); // union

    return vec4(vec3(0.0), 1.0 - step(0.0, -d));
}

vec4 realmfx_moon(float iTime, vec2 uv) {
    uv = gl_FragCoord.xy / ScreenSize.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= ScreenSize.x / ScreenSize.y;

    float t_linear = tlinear(iTime);
    float t_eased = teasedFx(t_linear);

    float static_rotation = -PI * 0.25;
    float c_static = cos(static_rotation);
    float s_static = sin(static_rotation);
    uv = vec2(uv.x * c_static - uv.y * s_static, uv.x * s_static + uv.y * c_static);

    float r1 = 0.7;
    float r2 = 0.45;
    float offset = 0.28;

    float minScale = 0.0001;
    float maxScale = 30.0;

    float scales = mix(maxScale, minScale, t_eased);
    uv /= scales;

    float d_crescent = crescentSDF(uv, r1, r2, offset);

    vec2 centerCirclePos = vec2(-0.01, 0.0);
    float centerCircleR = 0.17;
    float d_center = length(uv - centerCirclePos) - centerCircleR;

    vec2 lowerLeftPos = vec2(-0.54, 0.0);
    float lowerLeftR = 0.17;
    float d_lower  = length(uv - lowerLeftPos) - lowerLeftR;

    float d_union = min(d_crescent, d_center);
    float d = max(d_union, -d_lower); // subtraction

    float mask = step(0.0, -d);

    return vec4(vec3(0.0), 1.0-mask);
}

vec4 realmfx_comet(float iTime, vec2 uv) {
    uv = gl_FragCoord.xy / ScreenSize.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= ScreenSize.x / ScreenSize.y;
    uv /= 2.0;

    vec2 aspect = vec2(ScreenSize.x / ScreenSize.y, 1.0);
    vec2 p = uv;

    float t = tlinear(iTime);

    // path
    vec2 startN = vec2(-.1,1.1);
    vec2 endN   = vec2(1.7,-0.7);
    vec2 headN = mix(startN, endN, t);
    vec2 tailN = mix(startN, endN, max(0.0, t-1.0));
    vec2 head = (headN - 0.5) * aspect;
    vec2 tail = (tailN - 0.5) * aspect;

    float scale = ScreenSize.y/720.0;

    float zoom = 1.0;
    if (t > 0.5) {
        float delayedT = (t - 0.5)/0.5;
        zoom = 1.0 + 8.0 * delayedT;
    }

    vec2 pp = p / zoom;

    float headR = 0.12*scale*(0.8 + 0.4*t);
    float tailR = 0.15*scale*(0.8 + 0.4*t);

    float dTail = sdCapsuleWiggly(pp, tail, head, tailR, iTime);
    float dInner = sdCircleWiggly(pp, head, headR*1.0, iTime);

    float tailMask = step(dTail,0.0);
    float innerMask = step(dInner,0.0);

    float alpha = max(tailMask, -innerMask);

    vec3 color = vec3(alpha);
    color = mix(color, vec3(0.0), innerMask);

    return vec4(vec3(0.0), 1.0 - color.r);
}


