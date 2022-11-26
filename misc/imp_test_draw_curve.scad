section_radius_outer = 65.5;
section_center_outer = 65.0;
section_angles_outer = [10, 53.8];

section_radius_inner = 90.0;
section_center_inner = 115.0;
section_angles_inner = [10, 53.8];

section_angles_count = 50;

function getXSection(angle, center, radius) = center - radius * cos(angle);
function getYSection(angle, center, radius) = radius * sin(angle);

// given the input parameters (on the section plane), calculate a 3D coordinate
function getSectionCoordinate(xSection, ySection, angleFraction, sectionFraction, angleMultiplier, angleF) =
    let (angleA = pow(angleFraction + 0.05, 0.20) * angleMultiplier)
    let (angleB = 0) // pow(sectionFraction * angleFraction + 0.05, 0.3) * -10)
    // let (coordFraction = aSection / ((section_radius_inner + section_radius_outer) / 2))
    // let (angle2 = coordFraction * sectionFraction * 120) // ySection * 2 + aSection * sectionFraction * 0.60) // sqrt(ySection + 10) * 4
    let (angle2 = angleA + angleB + angleF)
    let (xPoly = cos(angle2) * xSection)
    let (yPoly = sin(angle2) * xSection)
    [xPoly, yPoly, ySection];  
 
function getSectionPoints(sectionFraction, angleMultiplier, angleF) = [
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
        getSectionCoordinate(xSection, ySection, angleFraction, sectionFraction, angleMultiplier, angleF)
    ];
    
    
module plotPolyhedron1(angle, angleMultiplier) {
    points = [
        for(s = [0:stepSize:1])
            getSectionPoints(s, angleMultiplier, angle)
    ];
        
    function flatten(l) = [ for (a = l) for (b = a) b ] ;

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
    // rotate(angle)
    polyhedron(points=flatten(points), faces=faces);
}

module plotPolyhedron2(angle1, angleMultiplier1, angle2, angleMultiplier2) {
    

    angleD = angle2 - angle1;
    // angleS = angleD / (stepCount - 1);
    points = [
        for(s = [0:stepSize:1])
            let (angleMultiplier = angleMultiplier1 + (angleMultiplier2 - angleMultiplier1) * s)
            let (angleFixed = angle1 + (angle2 - angle1) * s)
            getSectionPoints(0, angleMultiplier, angleFixed)
    ];
        
    function flatten(l) = [ for (a = l) for (b = a) b ] ;

echo (points);
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
            echo (faces);
    // rotate(angle, 0, 0)
    polyhedron(points=flatten(points), faces=faces);
}


stepCount = 15;
stepSize = 1 / stepCount; // 0.50; 

// for(p = [0:36:360])
plotPolyhedron1(0, 180);
plotPolyhedron1(11, 170.5);

plotPolyhedron2(11, 170.5, 36, 180);

