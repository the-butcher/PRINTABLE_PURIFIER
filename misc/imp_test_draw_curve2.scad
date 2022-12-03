// precision along the resulting body
section_angles_count = 50;

sectionDefOO = [63.4, 115.0, 10.0, 54.0]; // outer faces of the outer impeller shell
sectionDefOI = [65.0, 115.0, 10.0, 54.0]; // inner faces of the outer impeller shell

sectionDefII = [90.0, 115.0, 10.0, 54.0]; // inner faces of the inner impeller shell
sectionDefIO = [91.6, 115.0, 10.0, 54.0]; // outer faces of the inner impeller shell

sectionDefOS = [sectionDefOO, sectionDefOI]; // outer shell
sectionDefWN = [sectionDefOI, sectionDefII]; // wings
sectionDefIS = [sectionDefII, sectionDefIO]; // inner shell

indexOuter = 0;
indexInner = 1;

// for given angle, center and radius calculate the x coordinate of a point on the rotational section
function getXSection(angle, center, radius) = center - radius * cos(angle);

// for given angle, center and radius calculate the y coordinate of a point on the rotational section
function getYSection(angle, center, radius) = radius * sin(angle);

function getFSection(radius) = (radius - 65.0) / (90.0 - 65.0);

// given the input parameters (on the section plane), calculate a 3D coordinate
function getSectionCoordinate(xSection, ySection, angleFraction, sectionFraction, angleF, offsetDistance) =
    // rotates by y-coordinate (effectively just spiraling up)
    let (angleA = ySection * 0.5) // ySection * 0.5
    let (angleB = pow(angleFraction + 0.10, 0.5) * 90) // pow(angleFraction + 0.10, 0.5) * 90
    let (angleC = pow(1 - sectionFraction, 2) * 10  ) // pow(1 - sectionFraction, 2) * 10 
    let (angleD = offsetDistance / (xSection * 2 * PI / 360)) // offsetDistance / (xSection * 2 * PI / 360)
    let (angle2 = angleA + angleB + angleC + angleD + angleF)
    let (xPoly = cos(angle2) * xSection)
    let (yPoly = sin(angle2) * xSection)
    [xPoly, yPoly, ySection];  
 
function getSectionPoints(radius, angleF, offsetDistance, sectionDef) = [
    // the section angle along the outer curve
    let (sectionFraction = getFSection(radius))
    let (aSection0 = sectionDef[indexInner][2] - (sectionDef[indexOuter][2] - sectionDef[indexInner][2]) * sectionFraction)
    // the section angle along the inner curve
    let (aSection1 = sectionDef[indexOuter][3] - (sectionDef[indexOuter][3] - sectionDef[indexInner][3]) * sectionFraction)
    // split by section_angles_count along the section curve
    for(i = [0:1:section_angles_count])
        let (angleFraction = i / section_angles_count)
        // section angle as of section curve and current step
        let (aSection = aSection0 - (aSection0 - aSection1) * angleFraction)
        // center as of section curve and current step
        let (cSection = sectionDef[indexOuter][1] - (sectionDef[indexOuter][1] - sectionDef[indexInner][1]) * sectionFraction)
        // radius as of section curve and current step
        // let (rSection = sectionDef[indexOuter][0] - (sectionDef[indexOuter][0] - sectionDef[indexInner][0]) * sectionFraction)
    let (rSection = radius)
        // x on the flat section curve
        let (xSection = getXSection(aSection, cSection, rSection))
        // y on the flat section curve
        let (ySection = getYSection(aSection, cSection, rSection))
        getSectionCoordinate(xSection, ySection, angleFraction, sectionFraction, angleF, offsetDistance)
    ];
    
// flattens an array by one level of depth
function flatten(l) = [ for (a = l) for (b = a) b ] ;

    
module plotPolyhedron1(angle, offsetDistance, stepCount, sectionDef) {
    
    stepSize = 1 / stepCount;
    // echo(stepSize);
    points = [
        for(s = [0:stepSize:1])
            let (radius = sectionDef[0][0] + (sectionDef[1][0] - sectionDef[0][0]) * s)
            // echo(radius)
            // echo(getFSection(radius))
            getSectionPoints(radius, angle, offsetDistance, sectionDef)
    ];
        
    faces_outer = [
        for(s = [0:1:stepCount - 1])
            let (index0 = (section_angles_count + 1) * s)
            let (index1 = (section_angles_count + 1) * (s + 1))
            for(a = [0:1:section_angles_count - 1])
                [a + index0, a + index1 + 0, a + index1 + 1]
    ]; 
    faces_inner = [
        for(s = [0:1:stepCount - 1])
            let (index0 = (section_angles_count + 1) * s)
            let (index1 = (section_angles_count + 1) * (s + 1))
            for(a = [0:1:section_angles_count - 1])
                [a + index0, a + index1 + 1, a + index0 + 1]
    ];        
    faces = concat(faces_outer, faces_inner);  
    polyhedron(points=flatten(points), faces=faces);
}

module plotPolyhedron2(radius, angle1, offsetDistance1, angle2, offsetDistance2, stepCount, sectionDef) {
    stepSize = 1 / stepCount;
    angleD = angle2 - angle1;
    points = [
        for(s = [0:stepSize:1])
            let (angleFixed = angle1 + (angle2 - angle1) * s)
            let (offsetDistance = offsetDistance1 + (offsetDistance2 - offsetDistance1) * s)
            // echo(radius)
            // echo(getFSection(radius))        
            getSectionPoints(radius, angleFixed, offsetDistance, sectionDef)
    ];
    faces_outer = [
        for(s = [0:1:stepCount - 1])
            let (index0 = (section_angles_count + 1) * s)
            let (index1 = (section_angles_count + 1) * (s + 1))
            for(a = [0:1:section_angles_count - 1])
                [a + index0 + 1, a + index1 + 1, a + index1 + 0]
    ];
    faces_inner = [
        for(s = [0:1:stepCount - 1])
            let (index0 = (section_angles_count + 1) * s)
            let (index1 = (section_angles_count + 1) * (s + 1))
            for(a = [0:1:section_angles_count - 1])
                [a + index0  + 1, a + index1 + 0, a + index0 + 0]
    ];     
    faces = concat(faces_outer, faces_inner);  
    polyhedron(points=flatten(points), faces=faces);
}



// wing portruding out
// plotPolyhedron1(0, 1, 1, sectionDefOS);
plotPolyhedron1(36, -1, 1, sectionDefOS);


// main wing
// plotPolyhedron1(0, 1, 16, sectionDefWN);
// plotPolyhedron1(36, -1, 16, sectionDefWN);

// wing portruding in
// plotPolyhedron1(0, 1, 1, sectionDefIS);
// plotPolyhedron1(36, -1, 1, sectionDefIS);


// main borders
// plotPolyhedron2(sectionDefWN[indexInner][0], 0, 1, 36, -1, 16, sectionDefWN);
// plotPolyhedron2(sectionDefWN[indexOuter][0], 0, 1, 36, -1, 16, sectionDefWN);

// portruded border (outer)
// plotPolyhedron2(sectionDefOS[indexOuter][0], 0, -1, 0, 1, 1, sectionDefWN);
// portruded border (inner)
// plotPolyhedron2(sectionDefIS[indexInner][0], 0, -1, 0, 1, 1, sectionDefWN);

