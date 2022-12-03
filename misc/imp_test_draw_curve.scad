section_radius_outer = 65.0;
section_center_outer = 115.0;
section_angles_outer = [10, 53.8];

section_radius_inner = 90.0;
section_center_inner = 115.0;
section_angles_inner = [10, 53.8];

// precision along the resulting body
section_angles_count = 50;

// precision across the resulting body
stepCount = 15;
stepSize = 1 / stepCount; // 0.50; 

// for given angle, center and radius calculate the x coordinate of a point on the rotational section
function getXSection(angle, center, radius) = center - radius * cos(angle);

// for given angle, center and radius calculate the y coordinate of a point on the rotational section
function getYSection(angle, center, radius) = radius * sin(angle);

// given the input parameters (on the section plane), calculate a 3D coordinate
function getSectionCoordinate(xSection, ySection, angleFraction, sectionFraction, angleMultiplier, angleF, offsetDistance) =
    // rotates by y-coordinate (effectively just spiraling up)
    let (angleA = ySection * 0.5)
    // TODO :: magic numbers => move to variables
    let (angleB = pow(angleFraction + 0.10, 0.5) * angleMultiplier)
    let (angleC = pow(sectionFraction, 2) * 10)
    let (angleD = offsetDistance / (xSection * 2 * PI / 360))
    let (angle2 = angleA + angleB + angleC + angleD + angleF)
    let (xPoly = cos(angle2) * xSection)
    let (yPoly = sin(angle2) * xSection)
    [xPoly, yPoly, ySection];  
 
function getSectionPoints(sectionFraction, angleMultiplier, angleF, offsetDistance) = [
    // the section angle along the outer curve
    let (aSection0 = section_angles_outer[0] - (section_angles_inner[0] - section_angles_outer[0]) * sectionFraction)
    // the section angle along the inner curve
    let (aSection1 = section_angles_inner[1] - (section_angles_inner[1] - section_angles_outer[1]) * sectionFraction)
    // split by section_angles_count along the section curve
    for(i = [0:1:section_angles_count])
        let (angleFraction = i / section_angles_count)
        // section angle as of section curve and current step
        let (aSection = aSection0 - (aSection0 - aSection1) * angleFraction)
        // center as of section curve and current step
        let (cSection = section_center_inner - (section_center_inner - section_center_outer) * sectionFraction)
        // radius as of section curve and current step
        let (rSection = section_radius_inner - (section_radius_inner - section_radius_outer) * sectionFraction)
        // x on the flat section curve
        let (xSection = getXSection(aSection, cSection, rSection))
        // y on the flat section curve
        let (ySection = getYSection(aSection, cSection, rSection))
        getSectionCoordinate(xSection, ySection, angleFraction, sectionFraction, angleMultiplier, angleF, offsetDistance)
    ];
    
// flattens an array by one level of depth
function flatten(l) = [ for (a = l) for (b = a) b ] ;

    
module plotPolyhedron1(angle, angleMultiplier, offsetDistance) {
    points = [
        for(s = [0:stepSize:1])
            getSectionPoints(s, angleMultiplier, angle, offsetDistance)
    ];
    faces_outer = [
        for(s = [0:1:stepCount - 1])
            for(a = [0:1:section_angles_count - 1])
                let (index0 = (section_angles_count + 1) * s)
                let (index1 = (section_angles_count + 1) * (s + 1))
                [a + index0, a + index0 + 1, a + index1 + 1]
    ];
    faces_inner = [
        for(s = [0:1:stepCount - 1])
            for(a = [0:1:section_angles_count - 1])
                let (index0 = (section_angles_count + 1) * s)
                let (index1 = (section_angles_count + 1) * (s + 1))
                [a + index1 + 1, a + index1, a + index0]
    ];        
    faces = concat(faces_outer, faces_inner);  
    polyhedron(points=flatten(points), faces=faces);
}

module plotPolyhedron2(sectionFraction, angle1, angleMultiplier1, offsetDistance1, angle2, angleMultiplier2, offsetDistance2) {
    angleD = angle2 - angle1;
    points = [
        for(s = [0:stepSize:1])
            let (angleMultiplier = angleMultiplier1 + (angleMultiplier2 - angleMultiplier1) * s)
            let (angleFixed = angle1 + (angle2 - angle1) * s)
            let (offsetDistance = offsetDistance1 + (offsetDistance2 - offsetDistance1) * s)
            getSectionPoints(sectionFraction, angleMultiplier, angleFixed, offsetDistance)
    ];
    faces_outer = [
        for(s = [0:1:stepCount - 1])
            for(a = [0:1:section_angles_count - 1])
                let (index0 = (section_angles_count + 1) * s)
                let (index1 = (section_angles_count + 1) * (s + 1))
                [a + index0, a + index0 + 1, a + index1 + 1]
    ];
    faces_inner = [
        for(s = [0:1:stepCount - 1])
            for(a = [0:1:section_angles_count - 1])
                let (index0 = (section_angles_count + 1) * s)
                let (index1 = (section_angles_count + 1) * (s + 1))
                [a + index1 + 1, a + index1, a + index0]
    ];        
    faces = concat(faces_outer, faces_inner);  
    polyhedron(points=flatten(points), faces=faces);
}



// for(p = [0:36:360])
plotPolyhedron1(0, 90, 0.8);
plotPolyhedron1(36, 90, -0.8);

plotPolyhedron2(0, 0, 90, 0.8, 36, 90, -0.8);
plotPolyhedron2(1, 0, 90, 0.8, 36, 90, -0.8);

