//
//  ViewController.swift
//  MetalLearn
//
//  Created by chengxiaoyu on 2021/6/28.
//

import UIKit
import Metal
import MetalKit
import simd

class ViewController: UIViewController {
    
    @IBOutlet weak var rotationX: UISlider!
    @IBOutlet weak var rotationY: UISlider!
    @IBOutlet weak var rotationZ: UISlider!
    var mtkView: MTKView!
    var commandQueue: MTLCommandQueue!

    var pipelineState: MTLRenderPipelineState!
    var vertices:MTLBuffer?
    var numVertices:Int = 0
    
    var texture:MTLTexture?
    var uniforms: UnsafeMutablePointer<Uniforms>?
    var projectionMatrix: matrix_float4x4 = matrix_float4x4()
    var rotation: Float = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mtkView = MTKView(frame: CGRect(x: 0, y: 300, width: view.bounds.width, height: view.bounds.height))
        mtkView.isUserInteractionEnabled = true
        self.view.addSubview(mtkView)
        self.view.sendSubviewToBack(mtkView)
        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported")
            return
        }
//        guard let queue = defaultDevice.makeCommandQueue() else { return }
//        commandQueue = queue
        mtkView.device = defaultDevice
        mtkView.backgroundColor = UIColor.black
        mtkView.delegate = self

        setPipeline()
        setupVertex()
        setupTexture()
    }
    
    


}
//MARK: - 设置 metal 参数
extension ViewController {
    
    /// 设置渲染管道
    func setPipeline() {
        guard let defLib = mtkView.device?.makeDefaultLibrary() else {return}
        /// 插入定点着色器
        let vf = defLib.makeFunction(name: "vertexShader")
        let sf = defLib.makeFunction(name: "samplingShader")
        
        let pipelineStatusDescriptor = MTLRenderPipelineDescriptor()
        pipelineStatusDescriptor.vertexFunction = vf
        pipelineStatusDescriptor.fragmentFunction = sf
        
        pipelineStatusDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        do {
            pipelineState = try mtkView.device?.makeRenderPipelineState(descriptor: pipelineStatusDescriptor)
            commandQueue = mtkView.device?.makeCommandQueue()
        }catch {
            
        }
        
    }
    
    /// 设置定点
    func setupVertex() {
        // 顶点坐标，分别是x、y、z、w；    纹理坐标，x、y；
        let n1 = LYVertex.init(position: vector_float4(0.5, -0.5, 0.0, 1.0), textureCoordinate: vector_float2(1.0, 1.0))
        let n2 = LYVertex.init(position: vector_float4(-0.5, -0.5, 0.0, 1.0), textureCoordinate: vector_float2(0.0, 1.0))
        let n3 = LYVertex.init(position: vector_float4(-0.5,  0.5, 0.0, 1.0), textureCoordinate: vector_float2(0.0, 0.0))
        
        let n4 = LYVertex.init(position: vector_float4(0.5, -0.5, 0.0, 1.0), textureCoordinate: vector_float2(1.0, 1.0))
        let n5 = LYVertex.init(position: vector_float4(-0.5,  0.5, 0.0, 1.0), textureCoordinate: vector_float2(0.0, 0.0))
        let n6 = LYVertex.init(position: vector_float4(0.5,  0.5, 0.0, 1.0), textureCoordinate: vector_float2(1.0, 0.0))
        let points:[LYVertex] = [n1,n2,n3,n4,n5,n6]
        
        vertices = mtkView.device?.makeBuffer(bytes: points, length: MemoryLayout<LYVertex>.size*points.count, options: .storageModeShared)
        guard let m = vertices else {
            return
        }
        numVertices = points.count
        uniforms = UnsafeMutableRawPointer(m.contents()).bindMemory(to:Uniforms.self, capacity:1)
    }
    
    /// 设置纹理
    func setupTexture() {
        
        guard let image = UIImage(named: "photo_2021-06-28 18.06.24") else {
            return
        }
        let textDesc = MTLTextureDescriptor()
        textDesc.pixelFormat = .rgba8Unorm
        textDesc.width = Int(image.size.width)
        textDesc.height = Int(image.size.height)
        texture = mtkView.device?.makeTexture(descriptor: textDesc)
        let region:MTLRegion = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: Int(image.size.width), height: Int(image.size.height), depth: 1))
        if let point = loadInge(image) {
            self.texture?.replace(region: region, mipmapLevel: 0, withBytes: point, bytesPerRow: 4 * Int(image.size.width))
            free(point)
        }
        
        
    }
    
    func loadInge(_ image:UIImage) -> UnsafeMutableRawPointer? {
        guard let spimg = image.cgImage else{return nil}
        let width = spimg.width
        let height = spimg.height
        let data = calloc(width*height*4, MemoryLayout<UInt8>.size)
        guard let context = CGContext.init(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width*4, space: spimg.colorSpace!, bitmapInfo: spimg.bitmapInfo.rawValue) else { return nil}
        context.draw(spimg, in: CGRect(x: 0, y: 0, width: width, height: height))

        return data
    }
}

extension ViewController:MTKViewDelegate {
    
    private func updateDynamicBufferState() {
        /// Update the state of our uniform buffers before rendering
        uniforms = UnsafeMutableRawPointer(vertices!.contents() ).bindMemory(to:Uniforms.self, capacity:1)
    }
    
    private func updateGameState() {
        /// Update any game state before rendering
        
        uniforms?[0].projectionMatrix = projectionMatrix
        let x:Float = self.rotationX.value
        let y:Float = self.rotationY.value
        let z:Float = self.rotationZ.value
        let rotationAxis = SIMD3<Float>(1, 1, 1)
        let modelMatrix = matrix4x4_rotation(radians: rotation, axis: rotationAxis)
        let viewMatrix = matrix4x4_translation(x, y, -z)
        uniforms?[0].modelViewMatrix = simd_mul(viewMatrix, modelMatrix)
        rotation += 0.01
    }
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
    
        let buffer = commandQueue.makeCommandBuffer()
        self.updateDynamicBufferState()
        
        self.updateGameState()
        let renderPass = view.currentRenderPassDescriptor
        
        if let r = renderPass {
            r.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 1.0)
            let renderEncoder = buffer?.makeRenderCommandEncoder(descriptor: r)
            renderEncoder?.setViewport(MTLViewport(originX: 0, originY: 0, width: 640, height: 1136, znear: -1, zfar: 1))
            /// 渲染管道
            renderEncoder?.setRenderPipelineState(pipelineState)
            /// 设置定点缓存
            renderEncoder?.setVertexBuffer(vertices, offset: 0, index: 0)
            /// 设置纹理
            renderEncoder?.setFragmentTexture(texture, index: 0)
            
            renderEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: numVertices)
            
            renderEncoder?.endEncoding()
            /// 显示
            buffer?.present(view.currentDrawable!)
        }
        
        buffer?.commit()
    }
}
// Generic matrix math utility functions
func matrix4x4_rotation(radians: Float, axis: SIMD3<Float>) -> matrix_float4x4 {
    let unitAxis = normalize(axis)
    let ct = cosf(radians)
    let st = sinf(radians)
    let ci = 1 - ct
    let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
    return matrix_float4x4.init(columns:(vector_float4(    ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
                                         vector_float4(x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0),
                                         vector_float4(x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0),
                                         vector_float4(                  0,                   0,                   0, 1)))
}

func matrix4x4_translation(_ translationX: Float, _ translationY: Float, _ translationZ: Float) -> matrix_float4x4 {
    return matrix_float4x4.init(columns:(vector_float4(1, 0, 0, 0),
                                         vector_float4(0, 1, 0, 0),
                                         vector_float4(0, 0, 1, 0),
                                         vector_float4(translationX, translationY, translationZ, 1)))
}

func matrix_perspective_right_hand(fovyRadians fovy: Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
    let ys = 1 / tanf(fovy * 0.5)
    let xs = ys / aspectRatio
    let zs = farZ / (nearZ - farZ)
    return matrix_float4x4.init(columns:(vector_float4(xs,  0, 0,   0),
                                         vector_float4( 0, ys, 0,   0),
                                         vector_float4( 0,  0, zs, -1),
                                         vector_float4( 0,  0, zs * nearZ, 0)))
}

func radians_from_degrees(_ degrees: Float) -> Float {
    return (degrees / 180) * .pi
}
