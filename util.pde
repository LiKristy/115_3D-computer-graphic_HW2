public void CGLine(float x1, float y1, float x2, float y2) {
    int x = round(x1);
    int y = round(y1);
    int xEnd = round(x2);
    int yEnd = round(y2);
    int dx = abs(xEnd - x);
    int dy = abs(yEnd - y);
    int sx = (x < xEnd) ? 1 : -1;
    int sy = (y < yEnd) ? 1 : -1;
    int err = dx - dy;
    while (true) {
        drawPoint(x, y, color(0));
        if (x == xEnd && y == yEnd) {
            break;
        }
        int e2 = 2 * err;
        if (e2 > -dy) {
            err -= dy;
            x += sx;
        }
        if (e2 < dx) {
            err += dx;
            y += sy;
        }
    }

}


public boolean outOfBoundary(float x, float y) {
    if (x < 0 || x >= width || y < 0 || y >= height)
        return true;
    return false;
}

public void drawPoint(float x, float y, color c) {
    int index = (int) y * width + (int) x;
    if (outOfBoundary(x, y))
        return;
    pixels[index] = c;
}

public float distance(Vector3 a, Vector3 b) {
    Vector3 c = a.sub(b);
    return sqrt(Vector3.dot(c, c));
}

// Even-odd ray casting (PNPOLY)
boolean pnpoly(float x, float y, Vector3[] vertexes) {
    boolean inside = false;
    int n = vertexes.length;
    for (int i = 0, j = n - 1; i < n; j = i++) {
        float xi = vertexes[i].x, yi = vertexes[i].y;
        float xj = vertexes[j].x, yj = vertexes[j].y;
        if (((yi > y) != (yj > y)) &&
            (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
            inside = !inside;
        }
    }
    return inside;
}

public Vector3[] findBoundBox(Vector3[] v) {
    float minX = Float.MAX_VALUE, minY = Float.MAX_VALUE;
    float maxX = -Float.MAX_VALUE, maxY = -Float.MAX_VALUE;
    for (int i = 0; i < v.length; i++) {
        minX = min(minX, v[i].x);
        minY = min(minY, v[i].y);
        maxX = max(maxX, v[i].x);
        maxY = max(maxY, v[i].y);
    }
    Vector3 recordminV = new Vector3(minX, minY, 0);
    Vector3 recordmaxV = new Vector3(maxX, maxY, 0);
    Vector3[] result = { recordminV, recordmaxV };
    return result;
}

// 2D cross of (b-a) and (p-a)
float cross2(Vector3 a, Vector3 b, Vector3 p) {
    return (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x);
}

// Intersection of segment s-e with infinite line a-b
Vector3 lineIntersect(Vector3 s, Vector3 e, Vector3 a, Vector3 b) {
    float ds = cross2(a, b, s);
    float de = cross2(a, b, e);
    float t = ds / (ds - de);
    return new Vector3(s.x + (e.x - s.x) * t, s.y + (e.y - s.y) * t, 0);
}

public Vector3[] Sutherland_Hodgman_algorithm(Vector3[] points, Vector3[] boundary) {
    ArrayList<Vector3> input = new ArrayList<Vector3>();
    ArrayList<Vector3> output = new ArrayList<Vector3>();
    for (int i = 0; i < points.length; i += 1) {
        input.add(points[i]);
    }
    float area = 0;
    for (int i = 0; i < boundary.length; i++) {
        Vector3 p = boundary[i], q = boundary[(i + 1) % boundary.length];
        area += p.x * q.y - q.x * p.y;
    }
    float sign = area >= 0 ? 1 : -1;

    for (int i = 0; i < boundary.length; i++) {
        Vector3 a = boundary[i];
        Vector3 b = boundary[(i + 1) % boundary.length];
        output = new ArrayList<Vector3>();
        int n = input.size();
        for (int j = 0; j < n; j++) {
            Vector3 cur = input.get(j);
            Vector3 prev = input.get((j + n - 1) % n);
            boolean curIn  = sign * cross2(a, b, cur)  >= 0;
            boolean prevIn = sign * cross2(a, b, prev) >= 0;
            if (curIn) {
                if (!prevIn) output.add(lineIntersect(prev, cur, a, b));
                output.add(cur);
            } else if (prevIn) {
                output.add(lineIntersect(prev, cur, a, b));
            }
        }
        input = output;
        if (input.size() == 0) break;
    }

    output = input;
    Vector3[] result = new Vector3[output.size()];
    for (int i = 0; i < result.length; i += 1) {
        result[i] = output.get(i);
    }
    return result;
}
//Bonus: SSAA (2x2 super-sampling) 
boolean ENABLE_SSAA = true;

float ssaaCoverage(int px, int py, Vector3[] vertexes) {
    int hit = 0;
    for (int sy = 0; sy < 2; sy++) {
        for (int sx = 0; sx < 2; sx++) {
            float x = px + (sx + 0.5) / 2.0;
            float y = py + (sy + 0.5) / 2.0;
            if (pnpoly(x, y, vertexes)) hit++;
        }
    }
    return hit / 4.0;
}

void drawPointSSAA(int px, int py, color shapeColor, float coverage) {
    if (coverage <= 0 || outOfBoundary(px, py)) return;
    int index = py * width + px;
    pixels[index] = lerpColor(pixels[index], shapeColor, coverage);
}
