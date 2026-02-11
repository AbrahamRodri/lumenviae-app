//
//  HeaderView.swift
//  app
//
//  Created by Abraham Rodriguez on 2/10/26.
//

import SwiftUI

struct HeaderView: View {
    var onMenuTap: (() -> Void)?
    var onNotificationTap: (() -> Void)?

    var body: some View {
        HStack {
            Button(action: { onMenuTap?() }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 22))
                    .foregroundColor(AppColors.cream)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(Constants.appName)
                    .font(AppFonts.titleFont(22))
                    .tracking(4)
                    .foregroundColor(AppColors.gold)

                Text(Constants.appTagline)
                    .font(AppFonts.bodyFont(10))
                    .tracking(2)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Button(action: { onNotificationTap?() }) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.gold)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

#Preview {
    HeaderView()
        .background(AppColors.background)
}
