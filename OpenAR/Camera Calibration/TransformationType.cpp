//
//  TransformationType.cpp
//  SmartScan
//
//  Created by Cameron Palmer on 06.11.14.
//  Copyright (c) 2014 NTNU. All rights reserved.
//

#include "TransformationType.h"

#pragma mark - PIMPL

class TransformationImpl : public Transformation
{
private:
    friend class Transformation;

    explicit TransformationImpl(const Eigen::Matrix3f &rotation, const Eigen::Vector3f &translation)
    : _rotation(rotation), _translation(translation) {}

    Eigen::Matrix3f _rotation;
    Eigen::Vector3f _translation;

    Eigen::Matrix4f combinedMatrix(const Eigen::Matrix3f &rotation, const Eigen::Vector3f &translation) const;
};



#pragma mark - 

inline const TransformationImpl *Transformation::impl() const
{
    return static_cast<const TransformationImpl *>(this);
}

inline TransformationImpl *Transformation::impl()
{
    return static_cast<TransformationImpl *>(this);
}



#pragma mark - Factory methods

std::shared_ptr<Transformation> Transformation::create()
{
    return create(Eigen::Matrix3f::Identity(), Eigen::Vector3f::Zero());
}

std::shared_ptr<Transformation> Transformation::create(const Eigen::Matrix3f &rotation, const Eigen::Vector3f &translation)
{
    return std::shared_ptr<Transformation>(new TransformationImpl(rotation, translation));
}



#pragma mark - Getters

Eigen::Matrix3f &Transformation::rotation()
{
    return impl()->_rotation;
}

Eigen::Vector3f &Transformation::translation()
{
    return impl()->_translation;
}

const Eigen::Matrix3f &Transformation::rotation() const
{
    return impl()->_rotation;
}

const Eigen::Vector3f &Transformation::translation() const
{
    return impl()->_translation;
}

Eigen::Matrix4f Transformation::getMatrix4f() const
{
    return impl()->combinedMatrix(impl()->_rotation, impl()->_translation);
}

Eigen::Matrix4f Transformation::getInverted() const
{
    return impl()->combinedMatrix(impl()->_rotation.transpose(), -impl()->_translation);
}



#pragma mark - Static helper method

Eigen::Matrix4f TransformationImpl::combinedMatrix(const Eigen::Matrix3f &rotation, const Eigen::Vector3f &translation) const
{
    Eigen::Matrix4f combinedMatrix = Eigen::Matrix4f::Identity();
    for (int column = 0; column < 3; column++) {
        for (int row = 0; row < 3; row++) {
            // Copy rotation component
            combinedMatrix(row, column) = rotation(row, column);
        }

        // Copy translation component
        combinedMatrix(3, column) = translation(column);
    }

    return combinedMatrix;
}
