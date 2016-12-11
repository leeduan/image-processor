// playground containing an image processor that can apply one or more filters to an rgba image

import UIKit

// initial image
let image = UIImage(named: "sample")!

// filter interface
protocol Filter {
    func truncate(value: Int) -> UInt8
    func adjust(inout pixel: Pixel) -> Pixel
}

// abstract filter implementation
class AbstractFilter: Filter {
    private let RGB_MIN = 0
    private let RGB_MAX = 255

    internal var amount: Double

    init(amount: Double) {
        self.amount = amount
    }

    func truncate(value: Int) -> UInt8 {
        return UInt8(max(RGB_MIN, min(RGB_MAX, value)))
    }

    func adjust(inout pixel: Pixel) -> Pixel {
        NSException(name: "UnsupportedOperationException", reason: "Cannot adjust abstract filter", userInfo: nil).raise()
        return pixel
    }
}

// filter to adjust brightness by multiple e.g. 0.5 == 50%, 2.0 == 200%
class BrightnessFilter: AbstractFilter {
    private func adjust(color: UInt8) -> Int {
        return Int(Double(color) * amount)
    }

    override func adjust(inout pixel: Pixel) -> Pixel {
        // let value = Int(amount)
        pixel.red = truncate(adjust(pixel.red))
        pixel.green = truncate(adjust(pixel.green))
        pixel.blue = truncate(adjust(pixel.blue))
        return pixel
    }
}

// filter to adjust contrast -255 to +255
class ContrastFilter: AbstractFilter {
    private let MAGIC = 259.0
    private let SENSITIVITY = 128.0

    // TODO: algorithm to determine multiple correction, which requires an average brightness of image
    private func factor() -> Double {
        return (MAGIC * (amount + Double(self.RGB_MAX))) / (Double(self.RGB_MAX) * (MAGIC - amount))
    }

    private func adjust(color: UInt8, by fact: Double) -> Int {
        return Int(fact * (Double(color) - SENSITIVITY) + SENSITIVITY)
    }

    override func adjust(inout pixel: Pixel) -> Pixel {
        let fact = factor()
        pixel.red = truncate(adjust(pixel.red, by: fact))
        pixel.green = truncate(adjust(pixel.green, by: fact))
        pixel.blue = truncate(adjust(pixel.blue, by: fact))
        return pixel
    }
}

// filter to adjust gamma correction 0.01 to 7.99
class GammaFilter: AbstractFilter {
    private var gammaCorrection: Double {
        get {
            return 1.0 / amount
        }
    }

    func adjust(color: UInt8) -> Int {
        return Int(Double(self.RGB_MAX) * pow(Double(color) / Double(self.RGB_MAX), gammaCorrection))
    }

    override func adjust(inout pixel: Pixel) -> Pixel {
        pixel.red = truncate(adjust(pixel.red))
        pixel.green = truncate(adjust(pixel.green))
        pixel.blue = truncate(adjust(pixel.blue))
        return pixel
    }
}

// filter to adjust transparency from 0.0 to 1.0
class AlphaFilter: AbstractFilter {
    override func adjust(inout pixel: Pixel) -> Pixel {
        pixel.alpha = truncate(Int(amount * Double(self.RGB_MAX)))
        return pixel
    }
}

// image processor struct
struct ImageProcessor {
    var image: UIImage
    var filters: [Filter]

    // reasonable defaults
    private let defaultFilters: [String: Filter] = [
        "110% Brightness": BrightnessFilter(amount: 1.1),
        "3x Contrast": ContrastFilter(amount: 128),
        "Lena": GammaFilter(amount: 0.25),
        "Mandrill": GammaFilter(amount: 2.0),
        "80% Transparency": AlphaFilter(amount: 0.8),

        ]

    // constructor with image
    init(image: UIImage) {
        self.image = image
        self.filters = []
    }

    // constructor with image and filters
    init(image: UIImage, filters: [Filter]) {
        self.image = image
        self.filters = filters
    }

    // add a customer filter
    mutating func addFilter(filter: Filter) {
        self.filters.append(filter)
    }

    // add a default filter by name
    mutating func addFilter(name: String) {
        // TODO: handle nil
        self.filters.append(defaultFilters[name]!)
    }

    // apply filters and render image
    func process() -> UIImage {
        // TODO: handle nil
        var rgbaImage = RGBAImage(image: image)!

        for y in 0..<rgbaImage.height {
            for x in 0..<rgbaImage.width {
                let index = y * rgbaImage.width + x
                var pixel = rgbaImage.pixels[index]

                for filter in filters {
                    pixel = filter.adjust(&pixel)
                }
                rgbaImage.pixels[index] = pixel
            }
        }

        return rgbaImage.toUIImage()!
    }
}

// instantiate processor and apply filters
var imageProcessor = ImageProcessor(image: image)

// you can apply an instantiated filter
// imageProcessor.addFilter(ContrastFilter(amount: 30))

// you can apply a reasonable default
imageProcessor.addFilter("110% Brightness")
imageProcessor.addFilter("Mandrill")

// render image
imageProcessor.process()
