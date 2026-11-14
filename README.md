### 1. 變換矩陣(`Matrix4.pde`)

```java
void makeTrans(Vector3 t) {
  makeIdentity();
  m[3] = t.x;  m[7] = t.y;  m[11] = t.z;
}

void makeScale(Vector3 s) {
  makeIdentity();
  m[0] = s.x;  m[5] = s.y;  m[10] = s.z;
}

void makeRotZ(float a) {
  makeIdentity();
  m[0] = cos(a);  m[1] = -sin(a);
  m[4] = sin(a);  m[5] =  cos(a);
}
```

### 2. `util::pnpoly(float x, float y, Vector3[] vertexes)`(點是否在多邊形內)

使用 even-odd 射線法:從測試點往 +x 方向發出一條水平射線,計算與多邊形各邊的交點數,奇數個交點代表在內部,偶數個代表在外部。

```java
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
```

### 3. `util::findBoundBox(Vector3[] v)` (Find the boundary of a polygon) 

掃過所有頂點,分別記錄 x、y 的最小值與最大值。初始值使用 `Float.MAX_VALUE` / `-Float.MAX_VALUE`,因此頂點座標為負數時也不會出錯。回傳 `{ min, max }` 兩個點。

```java
float minX = Float.MAX_VALUE, minY = Float.MAX_VALUE;
float maxX = -Float.MAX_VALUE, maxY = -Float.MAX_VALUE;
for (int i = 0; i < v.length; i++) {
    minX = min(minX, v[i].x);  minY = min(minY, v[i].y);
    maxX = max(maxX, v[i].x);  maxY = max(maxY, v[i].y);
}
```

有了包圍盒後,填色時只需對盒內的像素呼叫 `pnpoly`,不必掃描整個畫布,因此渲染速度明顯加快。

### 4. `Vector3[] Sutherland_Hodgman_algorithm(Vector3[] points, Vector3[] boundary)` Sutherland-Hodgman 演算法

依序用 boundary 的每一條邊(視為無限長的直線)裁切目前的多邊形。對輸入多邊形的每條邊 (prev → cur),依兩端點在直線內外的情況處理:


做法:
- 用 `cross2(a, b, p) = (b-a) × (p-a)` 的正負號判斷點在邊的哪一側。
- 用有號面積(shoelace formula)判斷 boundary 是順時針或逆時針,再乘上對應的符號,所以不論 boundary 以哪種方向給定,結果都正確。
- 以兩端點對該直線的叉積值 `ds`、`de` 求參數 `t = ds / (ds - de)`,再用線性內插得到交點。
- 若某一輪裁切後沒有任何頂點,表示多邊形完全在邊界外,提前結束並回傳空陣列。

### 5. 加分題:SSAA

原本的填色是邊緣只有0或1，SSAA改成在每個像素內取2×2共4個子樣本,計算被多邊形涵蓋的比例,再依比例混合顏色。

```java
float ssaaCoverage(int px, int py, Vector3[] vertexes) {
    int hit = 0;
    for (int sy = 0; sy < 2; sy++) {
        for (int sx = 0; sx < 2; sx++) {
            float x = px + (sx + 0.5) / 2.0;   // 子樣本位於 .25 / .75
            float y = py + (sy + 0.5) / 2.0;
            if (pnpoly(x, y, vertexes)) hit++;
        }
    }
    return hit / 4.0;                           // 覆蓋率 0, .25, .5, .75, 1
}

void drawPointSSAA(int px, int py, color shapeColor, float coverage) {
    if (coverage <= 0 || outOfBoundary(px, py)) return;
    int index = py * width + px;
    pixels[index] = lerpColor(pixels[index], shapeColor, coverage);
}
```
- 全域變數 `ENABLE_SSAA` 可切換開關,比較前後差異。
在 `Shape.drawShape()` 中,填色迴圈依 `ENABLE_SSAA` 開關選擇:

```java
if (ENABLE_SSAA) {
    float cov = ssaaCoverage(i, j, t_pos);
    drawPointSSAA(i, j, color(100), cov);
} else if (pnpoly(i, j, t_pos)) {
    drawPoint(i, j, color(100));
}
```

- sample放在像素內的 0.25 與 0.75 位置,四個樣本均勻分布。
- 覆蓋率與畫面上原本的顏色用 `lerpColor` 混合,邊緣像素因此有5種灰階層次。


## 遇到的問題與發現

- Sutherland-Hodgman 的「內側」方向取決於 boundary 的頂點順序,因此改用有號面積決定判斷符號,避免寫死方向。
- 開啟 SSAA 後,若保留模板中的黑色輪廓線,會蓋掉抗鋸齒的邊緣,因此改為 SSAA 開啟時不畫輪廓。

## LLM

- 幫忙解決Sutherland-Hodgman方向的問題(有號面積)
- 撰寫一部分READ.md

