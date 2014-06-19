CSG::setColor = (r, g, b) ->
 @toPolygons().map (polygon) ->
    polygon.shared = [r, g, b]
    return
 return

gl = GL.create()

define 'shaders', (exports, root) ->

  exports.black = new GL.Shader('''
    void main() {
      gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    }
    ''', '''
    void main() {
      gl_FragColor = vec4(0.0, 0.0, 0.0, 0.1);
    }
    ''')

  exports.lighting = new GL.Shader('''
    varying vec3 color;
    varying vec3 normal;
    varying vec3 light;
    void main() {
      const vec3 lightDir = vec3(1.0, 2.0, 3.0) / 3.741657386773941;
      light = (gl_ModelViewMatrix * vec4(lightDir, 0.0)).xyz;
      color = gl_Color.rgb;
      normal = gl_NormalMatrix * gl_Normal;
      gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    }
    ''', '''
    varying vec3 color;
    varying vec3 normal;
    varying vec3 light;
    void main() {
      vec3 n = normalize(normal);
      float diffuse = max(0.0, dot(light, n));
      float specular = pow(max(0.0, -reflect(light, n).z), 32.0) * sqrt(diffuse);
      gl_FragColor = vec4(mix(color * (0.3 + 0.7 * diffuse), vec3(1.0), specular), 1.0);
    }
    ''')

  return

define 'spoke', (exports, root) ->

  angleX = 20
  angleY = -20
  mesh = null
  width = 600
  height = 600
  unit = 0.0034883720930232558 / 1.4

  cfg = 
    across: 2
    down: 2
    width: 400
    depth: 250
    height: 300
    spacing: 20

  render = (forceFit) ->
    totalWidth = (cfg.width * cfg.across) + (cfg.spacing * (cfg.across + 1))
    totalHeight = (cfg.height * cfg.down) + (cfg.spacing * (cfg.down + 1))
    totalDepth = cfg.depth + cfg.spacing
    if forceFit
      unit = 3.2 / Math.max(totalWidth, totalHeight, totalDepth)
    subX = (cfg.width * unit) / 2
    subY = (cfg.height * unit) / 2
    subZ = (cfg.depth * unit) / 2
    subSpace = cfg.spacing * unit
    radiusX = (totalWidth * unit) / 2
    radiusY = (totalHeight * unit) / 2
    radiusZ = (totalDepth * unit) / 2
    originX = subSpace + subX - radiusX
    originY = subSpace + subY - radiusY
    originZ = subSpace + subZ - radiusZ
    solid = CSG.cube(radius: [radiusX, radiusY, radiusZ])
    solid.setColor(0.890625, 0.75, 0.5546875)
    fixup = 1
    across = cfg.across + fixup
    initY = originY
    while across -= 1
      down = cfg.down + fixup
      originY = initY
      while down -= 1
        shelf = CSG.cube(center: [originX, originY, originZ], radius: [subX, subY, subZ])
        shelf.setColor(0.890625, 0.75, 0.5546875)
        solid = solid.subtract(shelf)
        originY += subY + subY + subSpace
      originX += subX + subX + subSpace
    mesh = solid.toMesh()

  exports.init = ->

    gl.canvas.width = width
    gl.canvas.height = height
    gl.viewport(0, 0, width, height)
    gl.matrixMode(gl.PROJECTION)
    gl.loadIdentity()
    gl.perspective(45, width / height, 0.1, 1000)
    gl.matrixMode(gl.MODELVIEW)

    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    gl.clearColor(0.93, 0.93, 0.93, 1)
    gl.clearColor(1, 1, 1, 1)
    gl.enable(gl.DEPTH_TEST)
    gl.enable(gl.CULL_FACE)
    gl.polygonOffset(1, 1)

    gl.onmousemove = (e) ->
      if e.dragging
        angleY += e.deltaX * 2
        angleX += e.deltaY * 2
        angleX = Math.max(-90, Math.min(90, angleX))
        gl.ondraw()
      return

    gl.ondraw = ->
      gl.makeCurrent()
      gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
      gl.loadIdentity()
      gl.translate(0, 0, -5)
      gl.rotate(angleX, 1, 0, 0)
      gl.rotate(angleY, 0, 1, 0)
      gl.enable(gl.POLYGON_OFFSET_FILL)
      shaders.lighting.draw(mesh, gl.TRIANGLES)
      gl.disable(gl.POLYGON_OFFSET_FILL)
      gl.enable(gl.BLEND)
      shaders.black.draw(mesh, gl.LINES)
      gl.disable(gl.BLEND)
      return

    handleParam = (param) ->
      return ->
        cfg[param] = parseInt(this.value, 10)
        render()
        gl.ondraw()
        return

    opts = [
      ['Columns', 'across', 1, 5, 1]
      ['Rows', 'down', 1, 4, 1]
      ['Width', 'width', 200, 600, 5]
      ['Height', 'height', 200, 600, 5]
      ['Depth', 'depth', 200, 400, 5]
      ]

    mkdiv = (className, html) ->
      el = document.createElement('div')
      el.className = className
      el.innerHTML = html
      return el

    $custom = document.getElementById('custom')
    for [title, param, min, max, step] in opts
      el = mkdiv 'opt', "<div class='title'>#{title}</div>"
      eli = document.createElement('input')
      eli.className = 'slider'
      eli.type = 'range'
      eli.min = min
      eli.max = max
      eli.step = step
      eli.value = cfg[param]
      eli.oninput = handleParam(param)
      pre = mkdiv 'pre', min
      post = mkdiv 'post', max
      el.appendChild(pre)
      el.appendChild(eli)
      el.appendChild(post)
      $custom.appendChild(el)

    fit = document.createElement('button')
    fit.className = 'fit'
    fit.innerHTML = 'Fit within area'
    fit.onclick = ->
      render(true)
      gl.ondraw()
      return

    $custom.appendChild(fit)
    render()
    document.getElementById('viewer').appendChild gl.canvas
    gl.ondraw()

    return

  return
