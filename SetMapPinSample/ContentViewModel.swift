//
//  ContentViewModel.swift
//  SetMapPinSample
//
//  Created by 花形春輝 on 2023/01/15.
//

import SwiftUI
import MapKit

struct PinItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

class ContentViewModel : NSObject, ObservableObject, MKLocalSearchCompleterDelegate{
    /// 位置情報検索クラス
    var completer = MKLocalSearchCompleter()
    /// 場所
    @Published var location = ""
    /// 検索クエリ
    @Published var searchQuery = ""
    /// 位置情報検索結果
    @Published var completions: [MKLocalSearchCompletion] = []
    
    /// 座標情報
    /// CLLocationCoordinate2D:緯度経度、縮尺
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6586, longitude: 139.7454)
        , span: MKCoordinateSpan(latitudeDelta: 100, longitudeDelta: 100))
    /// ピン情報
    @Published var pinItems:[PinItem] = []
    
    override init(){
        super.init()
        
        // 検索情報初期化
        completer.delegate = self
        
        // 場所のみ(住所を省く)
        completer.resultTypes = .pointOfInterest
    }
    
    /// 住所変更時
    func onSearchLocation() {
        // マップ表示中の目的地と同じなら何もしない
        if searchQuery == location {
            completions = []
            return
        }
        
        // 検索クエリ設定
        searchQuery = location
        
        // 場所が空の時、候補もクリア
        if searchQuery.isEmpty {
            completions = []
        } else {
            if completer.queryFragment != searchQuery {
                completer.queryFragment = searchQuery
            }
        }
    }
    
    /// 検索結果表示
    /// - Parameter completer: 検索結果の場所一覧
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            if self.searchQuery.isEmpty {
                self.completions = .init()
            } else {
                self.completions = completer.results
            }
        }
    }
    
    /// 場所をタップ
    /// - Parameter completion: タップされた場所
    func onLocationTap(_ completion:MKLocalSearchCompletion){
        DispatchQueue.main.async {
            // 場所を選択
            self.location = completion.title
            self.searchQuery = self.location
            
            // ピン設定
            self.setPin()
        }
    }
    
    /// ピンの設定
    func setPin(){
        /// 縮尺(1度=111km , 1/111 = 1kmの縮尺)
        let span:CLLocationDegrees = 1/111

        // 検索結果クリア
        completions = []
        
        // 検索条件設定
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = self.location
        
        // 検索実行
        MKLocalSearch(request: request).start { (response, error) in
            if let placemark = response?.mapItems.first?.placemark {
                DispatchQueue.main.async {
                    // 経度、緯度取得
                    let latitude = placemark.location?.coordinate.latitude ?? 0.0
                    let longitude = placemark.location?.coordinate.longitude ?? 0.0
                    
                    // マップの中心を設定
                    self.region = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        , span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span))

                    // ピン設定
                    self.pinItems = [PinItem(coordinate: .init(latitude: latitude, longitude: longitude))]
                }
            }
        }
    }
}
