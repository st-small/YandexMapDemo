import YandexMapsMobile
import UIKit

private let mockObjects = [
    YMKPoint(latitude: 55.761378, longitude: 37.609009),
    YMKPoint(latitude: 55.752508, longitude: 37.623150),
    YMKPoint(latitude: 55.760257, longitude: 37.618535)
]

final class ViewController: UIViewController {
    
    private let mapView = YMKMapView(frame: .zero, vulkanPreferred: true)!
    private var mapObjects = [YMKPlacemarkMapObject]()
    private var detailView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.brown.withAlphaComponent(0.5)
        view.layer.cornerRadius = 15
        return view
    }()
    
    private var detailViewHeight: NSLayoutConstraint!
    private var detailViewBottom: NSLayoutConstraint!
    private var selectedPoint: YMKPoint!
    
    // MARK: - Constants
    private let defaultZoom: Float = 14
    private let selectedZoom: Float = 16
    private let userPosition = YMKPoint(
        latitude: 55.755864,
        longitude: 37.617698
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureMapView()
        configureDetailView()
        moveToUserGeo()
        addObjects()
    }
    
    private func configureNavigation() {
        let zoomIn = UIBarButtonItem(
            image: UIImage(systemName: "plus.magnifyingglass"),
            style: .plain,
            target: self,
            action: #selector(zoomIn)
        )
        
        let zoomOut = UIBarButtonItem(
            image: UIImage(systemName: "minus.magnifyingglass"),
            style: .plain,
            target: self,
            action: #selector(zoomOut)
        )
        
        let locate = UIBarButtonItem(
            image: UIImage(systemName: "location"),
            style: .plain,
            target: self,
            action: #selector(moveToUserGeo)
        )
        
        navigationItem.rightBarButtonItems = [locate, zoomOut, zoomIn]
    }
    
    private func configureMapView() {
        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let logoAlignment = YMKLogoAlignment(
            horizontalAlignment: .left,
            verticalAlignment: .bottom
        )
        mapView.mapWindow.map.logo.setAlignmentWith(logoAlignment)
        mapView.mapWindow.map.addCameraListener(with: self)
        mapView.mapWindow.map.addInputListener(with: self)
    }
    
    private func configureDetailView() {
        view.addSubview(detailView)
        
        detailViewHeight = detailView.heightAnchor.constraint(equalToConstant: 100)
        detailViewHeight.isActive = true
        detailViewBottom = detailView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: detailViewHeight.constant)
        detailViewBottom.isActive = true
        NSLayoutConstraint.activate([
            detailView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            detailView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideDetailView))
        detailView.addGestureRecognizer(tapGesture)
    }
    
    @objc
    private func moveToUserGeo() {
        let cameraPosition = YMKCameraPosition(
            target: userPosition,
            zoom: defaultZoom,
            azimuth: 0,
            tilt: 0
        )
        let animation = YMKAnimation(type: .smooth, duration: 0.3)
        
        mapView.mapWindow.map.move(
            with: cameraPosition,
            animation: animation
        )
        
        hideDetailView()
    }
    
    private func addObjects() {
        mockObjects.forEach { point in
            let image = UIImage(resource: .placemarkSmall)
            let placemark = mapView.mapWindow.map.mapObjects.addPlacemark()
            placemark.geometry = point
            placemark.setIconWith(image)
            placemark.addTapListener(with: self)
            mapObjects.append(placemark)
        }
    }
    
    private func deselectAllPlacemarks() {
        selectedPoint = nil
        mapObjects.forEach { placemark in
            let mainImage = UIImage(resource: .placemarkSmall)
            placemark.setIconWith(mainImage)
        }
    }
    
    @objc
    private func zoomIn() {
        zoomAction(true)
    }
    
    @objc
    private func zoomOut() {
        zoomAction(false)
    }
    
    private func zoomAction(_ shouldIncrease: Bool) {
        let newZoom = shouldIncrease
        ? mapView.mapWindow.map.cameraPosition.zoom + 1
        : mapView.mapWindow.map.cameraPosition.zoom - 1
        
        let cameraPosition = YMKCameraPosition(
            target: mapView.mapWindow.map.cameraPosition.target,
            zoom: newZoom,
            azimuth: 0,
            tilt: 0
        )
        let animation = YMKAnimation(type: .smooth, duration: 0.3)
        
        mapView.mapWindow.map.move(
            with: cameraPosition,
            animation: animation
        )
        
        hideDetailView()
    }
    
    private func showDetailView() {
        view.setNeedsLayout()
        let randomHeight = CGFloat.random(in: 100...300)
        detailViewHeight.constant = randomHeight
        detailViewBottom.constant = 0
        UIView.animate(withDuration: 0.35) {
            self.view.layoutIfNeeded()
        }
        
        adjustMapViewWithSelectedPlacemark(randomHeight)
    }
    
    @objc
    private func hideDetailView() {
        view.setNeedsLayout()
        detailViewBottom.constant = detailViewHeight.constant
        UIView.animate(withDuration: 0.35) {
            self.view.layoutIfNeeded()
        }
        
        deselectAllPlacemarks()
    }
    
    private func adjustMapViewWithSelectedPlacemark(_ sheetHeight: CGFloat) {
        if mapView.mapWindow.map.cameraPosition.zoom != selectedZoom {
            let zoomPosition = YMKCameraPosition(
                target: selectedPoint,
                zoom: selectedZoom,
                azimuth: 0,
                tilt: 0
            )
            mapView.mapWindow.map.move(
                with: zoomPosition,
                animation: YMKAnimation(
                    type: .smooth,
                    duration: 0.1
                )) { _ in
                    self.focusSelectedPharmacyPlacemark(sheetHeight)
                }
        } else {
            focusSelectedPharmacyPlacemark(sheetHeight)
        }
    }
    
    private func focusSelectedPharmacyPlacemark(_ translation: CGFloat) {
        let mainScreenPoint = mapView.mapWindow.worldToScreen(
            withWorldPoint: selectedPoint
        ) ?? .init()
    
        let updatedScreenPoint = YMKScreenPoint(
            x: mainScreenPoint.x,
            y: mainScreenPoint.y + Float(translation + view.safeAreaInsets.bottom)
        )
        let mainPoint = mapView.mapWindow.screenToWorld(with: updatedScreenPoint) ?? .init()
        
        let position = YMKCameraPosition(
            target: mainPoint,
            zoom: selectedZoom,
            azimuth: 0,
            tilt: 0
        )
        
        mapView.mapWindow.map.move(
            with: position,
            animation: YMKAnimation(
                type: .smooth,
                duration: 0.3
            )
        )
    }
}

extension ViewController: YMKMapCameraListener {
    func onCameraPositionChanged(with map: YMKMap, cameraPosition: YMKCameraPosition, cameraUpdateReason: YMKCameraUpdateReason, finished: Bool) {
        guard cameraUpdateReason == .gestures else { return }
        hideDetailView()
    }
}

extension ViewController: YMKMapInputListener {
    func onMapTap(with map: YMKMap, point: YMKPoint) {
        hideDetailView()
    }
    func onMapLongTap(with map: YMKMap, point: YMKPoint) { }
}

extension ViewController: YMKMapObjectTapListener {
    func onMapObjectTap(with mapObject: YMKMapObject, point: YMKPoint) -> Bool {
        if let placemark = mapObject as? YMKPlacemarkMapObject, selectedPoint != placemark.geometry {
            deselectAllPlacemarks()
            
            let selectedImage = UIImage(resource: .placemarkBig)
            placemark.setIconWith(selectedImage)
            
            selectedPoint = placemark.geometry
            showDetailView()
        }
        
        return true
    }
}
