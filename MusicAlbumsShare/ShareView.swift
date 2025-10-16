//
//  ShareView.swift
//  MusicAlbums
//
//  Created by Daichi Fujita on 2025/08/11.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI

struct ShareView: View {
    
    let result: HandlingResult?

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    if result != nil {
                        close()
                    }
                }
            
            VStack(spacing: 20) {
                Spacer()
                
                switch result {
                case .success:
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("保存完了")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("タップで閉じる")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(40)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 10)
                
                case let .failure(error):
                    VStack(spacing: 16) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("保存に失敗")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("タップで閉じる")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(40)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 10)
                
                case nil:
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("保存中...")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .padding(40)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 10)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    func close() {
        NotificationCenter.default.post(name: NSNotification.Name("close"), object: nil)
    }
}

