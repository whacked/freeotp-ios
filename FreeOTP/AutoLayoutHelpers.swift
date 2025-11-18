//
//  AutoLayoutHelpers.swift
//  FreeOTP
//
//  A minimal subset of TinyConstraints used to express layouts in code.
//

import UIKit

typealias Constraint = NSLayoutConstraint

protocol Constrainable {
    var leftAnchor: NSLayoutXAxisAnchor { get }
    var rightAnchor: NSLayoutXAxisAnchor { get }
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
    var widthAnchor: NSLayoutDimension { get }
    var heightAnchor: NSLayoutDimension { get }
    var centerXAnchor: NSLayoutXAxisAnchor { get }
    var centerYAnchor: NSLayoutYAxisAnchor { get }
}

extension UIView: Constrainable {}
extension UILayoutGuide: Constrainable {}

private extension UIView {
    func prepareForConstraints() {
        if translatesAutoresizingMaskIntoConstraints {
            translatesAutoresizingMaskIntoConstraints = false
        }
    }

    func assertSuperview() -> UIView {
        guard let superview = superview else {
            preconditionFailure("Attempted to create constraints before adding the view to a superview")
        }
        return superview
    }
}

extension UIView {
    func setCompressionResistance(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) {
        setContentCompressionResistancePriority(priority, for: axis)
    }

    @discardableResult
    func topToSuperview(offset: CGFloat = 0) -> Constraint {
        prepareForConstraints()
        let constraint = topAnchor.constraint(equalTo: assertSuperview().topAnchor, constant: offset)
        constraint.isActive = true
        return constraint
    }

    @discardableResult
    func bottomToSuperview(offset: CGFloat = 0) -> Constraint {
        prepareForConstraints()
        let constraint = bottomAnchor.constraint(equalTo: assertSuperview().bottomAnchor, constant: offset)
        constraint.isActive = true
        return constraint
    }

    @discardableResult
    func leftToSuperview(offset: CGFloat = 0) -> Constraint {
        prepareForConstraints()
        let constraint = leftAnchor.constraint(equalTo: assertSuperview().leftAnchor, constant: offset)
        constraint.isActive = true
        return constraint
    }

    @discardableResult
    func rightToSuperview(offset: CGFloat = 0) -> Constraint {
        prepareForConstraints()
        let constraint = rightAnchor.constraint(equalTo: assertSuperview().rightAnchor, constant: offset)
        constraint.isActive = true
        return constraint
    }

    @discardableResult
    func centerYToSuperview(offset: CGFloat = 0) -> Constraint {
        prepareForConstraints()
        let constraint = centerYAnchor.constraint(equalTo: assertSuperview().centerYAnchor, constant: offset)
        constraint.isActive = true
        return constraint
    }

    @discardableResult
    func leftToRight(of constrainable: Constrainable, offset: CGFloat = 0) -> Constraint {
        prepareForConstraints()
        let constraint = leftAnchor.constraint(equalTo: constrainable.rightAnchor, constant: offset)
        constraint.isActive = true
        return constraint
    }

    @discardableResult
    func rightToLeft(of constrainable: Constrainable, offset: CGFloat = 0) -> Constraint {
        prepareForConstraints()
        let constraint = rightAnchor.constraint(equalTo: constrainable.leftAnchor, constant: offset)
        constraint.isActive = true
        return constraint
    }

    @discardableResult
    func widthToHeight(of constrainable: Constrainable, multiplier: CGFloat = 1.0) -> Constraint {
        prepareForConstraints()
        let constraint = widthAnchor.constraint(equalTo: constrainable.heightAnchor, multiplier: multiplier)
        constraint.isActive = true
        return constraint
    }

    @discardableResult
    func center(in view: UIView) -> [Constraint] {
        prepareForConstraints()
        let constraints = [centerXAnchor.constraint(equalTo: view.centerXAnchor),
                           centerYAnchor.constraint(equalTo: view.centerYAnchor)]
        NSLayoutConstraint.activate(constraints)
        return constraints
    }

    @discardableResult
    func size(to view: UIView, multiplier: CGFloat = 1.0) -> [Constraint] {
        prepareForConstraints()
        let constraints = [widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: multiplier),
                           heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: multiplier)]
        NSLayoutConstraint.activate(constraints)
        return constraints
    }

    @discardableResult
    func size(_ size: CGSize) -> [Constraint] {
        prepareForConstraints()
        let constraints = [widthAnchor.constraint(equalToConstant: size.width),
                           heightAnchor.constraint(equalToConstant: size.height)]
        NSLayoutConstraint.activate(constraints)
        return constraints
    }
}
